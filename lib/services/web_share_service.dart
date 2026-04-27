import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/services/network_transfer_service.dart';
import 'package:flux/utils/logger.dart';
import 'package:mime/mime.dart';

/// Download session tracking
class _DownloadSession {
  final String fileId;
  final String clientIp;
  final DateTime startedAt;
  int bytesSent;
  bool isComplete;

  _DownloadSession({
    required this.fileId,
    required this.clientIp,
    DateTime? startedAt,
    this.bytesSent = 0,
    this.isComplete = false,
  }) : startedAt = startedAt ?? DateTime.now();
}

/// Service for hosting files via HTTP web server for browser-based downloads
/// Supports concurrent downloads from multiple users
class WebShareService {
  static final WebShareService _instance = WebShareService._internal();
  factory WebShareService() => _instance;
  WebShareService._internal();

  HttpServer? _server;
  final List<FileMetadata> _sharedFiles = [];
  final Map<String, String> _filePaths = {};
  final Map<String, int> _downloadCounts = {};
  final Map<String, List<_DownloadSession>> _activeDownloads = {};
  final Map<String, StreamController<double>> _downloadProgress = {};
  final NetworkTransferService _networkService = NetworkTransferService();
  final Set<String> _activeClients = {};

  int? _serverPort;
  String? _serverAddress;
  int _maxConcurrentDownloads = 50; // Support up to 50 concurrent clients

  /// Start web server with dynamic port allocation
  /// Supports multiple concurrent connections
  Future<Map<String, dynamic>> startServer({List<MapEntry<FileMetadata, String>>? files}) async {
    try {
      // Stop existing server if running
      await stopServer();

      // Clear previous state
      _sharedFiles.clear();
      _filePaths.clear();
      _downloadCounts.clear();
      _activeDownloads.clear();
      _activeClients.clear();

      // Add new files if provided
      if (files != null) {
        for (final entry in files) {
          _sharedFiles.add(entry.key);
          _filePaths[entry.key.id] = entry.value;
          _downloadCounts[entry.key.id] = 0;
          _activeDownloads[entry.key.id] = [];
        }
      }

      // Allocate dynamic port
      _serverPort = await _networkService.allocateDynamicPort();

      // Start HTTP server with backlog for concurrent connections
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        _serverPort!,
        backlog: 128, // Allow 128 pending connections
        shared: true,
      );

      // Enable keep-alive for better concurrent performance
      _server!.idleTimeout = const Duration(minutes: 2);

      // Get server address
      final localIp = await _getLocalIpAddress();
      _serverAddress = 'http://$localIp:$_serverPort';

      AppLogger.info('Web share server started at $_serverAddress (max concurrent: $_maxConcurrentDownloads)');

      // Handle requests concurrently
      _server!.listen(
        _handleRequest,
        onError: (error) {
          AppLogger.error('Web server error', error);
        },
        onDone: () {
          AppLogger.info('Web server closed');
        },
      );

      return {
        'address': _serverAddress,
        'port': _serverPort,
        'url': _serverAddress,
        'maxConcurrent': _maxConcurrentDownloads,
      };
    } catch (e) {
      AppLogger.error('Failed to start web share server', e);
      rethrow;
    }
  }

  /// Get local IP address for sharing
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      // Prioritize WiFi/ethernet interfaces
      for (final interface in interfaces) {
        // Skip virtual/tunnel interfaces
        if (interface.name.contains('Virtual') || 
            interface.name.contains('Tunnel') ||
            interface.name.contains('Loopback')) {
          continue;
        }
        
        for (final addr in interface.addresses) {
          // Prefer 192.168.x.x or 10.x.x.x (local networks)
          if (addr.address.startsWith('192.168.') || 
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
      
      // Fallback to first available
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
      
      return '0.0.0.0';
    } catch (e) {
      AppLogger.error('Failed to get local IP', e);
      return '0.0.0.0';
    }
  }

  /// Stop the web server
  Future<void> stopServer() async {
    // Close all download progress streams
    for (final controller in _downloadProgress.values) {
      await controller.close();
    }
    _downloadProgress.clear();

    await _server?.close();
    _server = null;
    _serverPort = null;
    _serverAddress = null;
    
    AppLogger.info('Web share server stopped');
  }

  /// Add files to share
  void addFiles(List<MapEntry<FileMetadata, String>> files) {
    for (final entry in files) {
      if (!_sharedFiles.any((f) => f.id == entry.key.id)) {
        _sharedFiles.add(entry.key);
        _filePaths[entry.key.id] = entry.value;
        _downloadCounts[entry.key.id] = 0;
      }
    }
  }

  /// Remove a file from sharing
  void removeFile(String fileId) {
    _sharedFiles.removeWhere((f) => f.id == fileId);
    _filePaths.remove(fileId);
    _downloadCounts.remove(fileId);
    
    // Close progress stream if exists
    _downloadProgress[fileId]?.close();
    _downloadProgress.remove(fileId);
  }

  /// Clear all shared files
  void clearFiles() {
    _sharedFiles.clear();
    _filePaths.clear();
    _downloadCounts.clear();
    
    for (final controller in _downloadProgress.values) {
      controller.close();
    }
    _downloadProgress.clear();
  }

  /// Handle HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path;

    try {
      // CORS headers
      response.headers.add('Access-Control-Allow-Origin', '*');
      response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        response.statusCode = HttpStatus.ok;
        await response.close();
        return;
      }

      // Route handling
      if (path == '/' || path == '/index.html') {
        await _serveIndexPage(response);
      } else if (path == '/api/files') {
        await _serveFileList(response);
      } else if (path.startsWith('/download/')) {
        final fileId = path.substring('/download/'.length);
        await _serveFileDownload(request, response, fileId);
      } else if (path == '/api/stats') {
        await _serveStats(response);
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write('Not Found');
        await response.close();
      }
    } catch (e) {
      AppLogger.error('Error handling web request: $path', e);
      response.statusCode = HttpStatus.internalServerError;
      response.write('Internal Server Error');
      await response.close();
    }
  }

  /// Serve the main index page
  Future<void> _serveIndexPage(HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flux Share - Download Files</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
            background: #ffffff;
            min-height: 100vh;
            padding: 24px;
            color: #0f172a;
        }
        .container {
            max-width: 720px;
            margin: 0 auto;
        }
        .header {
            text-align: center;
            padding: 32px 20px 40px;
        }
        .logo {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 56px;
            height: 56px;
            background: linear-gradient(135deg, #6366f1 0%, #0ea5e9 100%);
            border-radius: 16px;
            margin-bottom: 20px;
            box-shadow: 0 10px 25px -5px rgba(99, 102, 241, 0.4);
        }
        .logo-icon {
            font-size: 28px;
            filter: grayscale(1) brightness(2);
        }
        .header h1 {
            font-size: 1.75rem;
            font-weight: 700;
            margin-bottom: 8px;
            color: #0f172a;
            letter-spacing: -0.025em;
        }
        .header p {
            font-size: 1rem;
            color: #64748b;
            margin-bottom: 16px;
        }
        .connection-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #f1f5f9;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.875rem;
            color: #475569;
            font-weight: 500;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            background: #22c55e;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        .card {
            background: #ffffff;
            border-radius: 24px;
            padding: 24px;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02), 0 10px 15px -3px rgba(0,0,0,0.05), 0 0 0 1px rgba(0,0,0,0.05);
            margin-bottom: 24px;
            border: 1px solid #f1f5f9;
        }
        .file-item {
            background: white;
            border-radius: 12px;
            padding: 14px 16px;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            border: 1px solid #e2e8f0;
            transition: all 0.2s ease;
        }
        .file-item:hover {
            border-color: #6366f1;
            box-shadow: 0 2px 8px rgba(99, 102, 241, 0.1);
        }
        .file-icon {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #6366f1 0%, #0ea5e9 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
            flex-shrink: 0;
            box-shadow: 0 2px 8px rgba(99, 102, 241, 0.2);
        }
        .file-info {
            flex: 1;
            min-width: 0;
        }
        .file-name {
            font-weight: 600;
            font-size: 0.9rem;
            color: #1e293b;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .file-size {
            color: #64748b;
            font-size: 0.8rem;
            font-weight: 500;
        }
        .download-btn {
            background: #6366f1;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 0.85rem;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s ease;
            flex-shrink: 0;
        }
        .download-btn:hover {
            background: #4f46e5;
            transform: translateY(-1px);
        }
        .download-btn:active {
            transform: translateY(0);
        }
        .download-btn.downloading {
            background: #f59e0b;
            pointer-events: none;
        }
        .progress-bar {
            width: 100%;
            height: 3px;
            background: #e2e8f0;
            border-radius: 2px;
            margin-top: 6px;
            overflow: hidden;
            display: none;
        }
        .progress-bar.active {
            display: block;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #6366f1 0%, #0ea5e9 100%);
            border-radius: 2px;
            transition: width 0.2s ease;
        }
        .download-count {
            background: #f1f5f9;
            color: #64748b;
            font-size: 0.75rem;
            padding: 4px 8px;
            border-radius: 6px;
            margin-left: 8px;
            font-weight: 600;
        }
        .empty-state {
            text-align: center;
            padding: 48px 20px;
            color: #64748b;
        }
        .empty-state-icon {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.6;
        }
        .footer {
            text-align: center;
            padding: 24px;
            color: #94a3b8;
            font-size: 0.875rem;
        }
        .footer a {
            color: #6366f1;
            text-decoration: none;
            font-weight: 500;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        @media (max-width: 640px) {
            body { padding: 16px; }
            .header { padding: 24px 16px 32px; }
            .header h1 { font-size: 1.5rem; }
            .card { padding: 16px; border-radius: 20px; }
            .file-item { flex-wrap: wrap; gap: 12px; padding: 12px; }
            .file-icon { width: 40px; height: 40px; font-size: 20px; }
            .file-info { width: 100%; order: 3; }
            .download-btn { width: 100%; justify-content: center; order: 2; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <span class="logo-icon">⬆️</span>
            </div>
            <h1>Flux Share</h1>
            <p>Download shared files directly to your device</p>
            <div class="connection-badge">
                <span class="status-dot"></span>
                <span>${_sharedFiles.length} file(s) available</span>
            </div>
        </div>
        
        <div class="card" id="fileList">
            ${_sharedFiles.isEmpty 
              ? '''<div class="empty-state">
                    <div class="empty-state-icon">📂</div>
                    <p>No files shared yet</p>
                 </div>'''
              : _sharedFiles.map((f) => '''<div class="file-item" id="file-${f.id}">
                    <div class="file-icon">${_getFileIconHtml(f.name)}</div>
                    <div class="file-info">
                        <div class="file-name">${f.name}</div>
                        <div class="file-size">${_formatSizeHtml(f.size)}</div>
                        <div class="progress-bar" id="progress-${f.id}">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                    </div>
                    <a href="/download/${f.id}" 
                       class="download-btn"
                       id="btn-${f.id}"
                       onclick="startDownload('${f.id}', event)">
                        ⬇️
                    </a>
                    ${_downloadCounts[f.id] != null && _downloadCounts[f.id]! > 0 
                      ? '<span class="download-count">${_downloadCounts[f.id]}</span>'
                      : ''}
                </div>''').join('')}
        </div>
        
        <div class="footer">
            <p>Powered by <a href="#">Flux</a> • Secure local file sharing</p>
        </div>
    </div>

    <script>
        let files = [];
        let downloadProgress = {};

        async function loadFiles() {
            try {
                const response = await fetch('/api/files');
                files = await response.json();
                renderFiles();
            } catch (error) {
                console.error('Failed to load files:', error);
                document.getElementById('fileList').innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">⚠️</div>
                        <p>Failed to load files. Please refresh the page.</p>
                    </div>
                `;
            }
        }

        function formatSize(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
        }

        function getFileIcon(name) {
            const ext = name.split('.').pop().toLowerCase();
            const icons = {
                'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️',
                'mp4': '🎬', 'mov': '🎬', 'avi': '🎬',
                'mp3': '🎵', 'wav': '🎵', 'flac': '🎵',
                'pdf': '📄', 'doc': '📝', 'docx': '📝', 'txt': '📝',
                'zip': '📦', 'rar': '📦', '7z': '📦',
                'apk': '📱', 'exe': '💻'
            };
            return icons[ext] || '📄';
        }

        function renderFiles() {
            const container = document.getElementById('fileList');
            
            if (files.length === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">📂</div>
                        <p>No files available for download</p>
                    </div>
                `;
                return;
            }

            container.innerHTML = files.map(file => '' +
                '<div class="file-item" id="file-' + file.id + '">' +
                    '<div class="file-icon">' + getFileIcon(file.name) + '</div>' +
                    '<div class="file-info">' +
                        '<div class="file-name">' + file.name + '</div>' +
                        '<div class="file-size">' + formatSize(file.size) + '</div>' +
                        '<div class="progress-bar ' + (downloadProgress[file.id] ? 'active' : '') + '" id="progress-' + file.id + '">' +
                            '<div class="progress-fill" style="width: ' + ((downloadProgress[file.id] || 0) * 100) + '%"></div>' +
                        '</div>' +
                    '</div>' +
                    '<a href="/download/' + file.id + '" ' +
                       'class="download-btn ' + (downloadProgress[file.id] ? 'downloading' : '') + '" ' +
                       'onclick="startDownload(\'' + file.id + '\', event)">' +
                        (downloadProgress[file.id] ? '⏳' : '⬇️') +
                    '</a>' +
                    (file.downloadCount > 0 ? '<span class="download-count">' + file.downloadCount + '</span>' : '') +
                '</div>'
            ).join('');
        }

        async function startDownload(fileId, event) {
            event.preventDefault();
            
            if (downloadProgress[fileId]) return;
            
            downloadProgress[fileId] = 0;
            updateDownloadUI(fileId);
            
            try {
                const response = await fetch('/download/' + fileId);
                const contentLength = response.headers.get('Content-Length');
                const reader = response.body.getReader();
                
                let receivedLength = 0;
                const chunks = [];
                
                while(true) {
                    const {done, value} = await reader.read();
                    
                    if (done) break;
                    
                    chunks.push(value);
                    receivedLength += value.length;
                    
                    if (contentLength) {
                        downloadProgress[fileId] = receivedLength / parseInt(contentLength);
                        updateDownloadUI(fileId);
                    }
                }
                
                // Combine chunks and download
                const blob = new Blob(chunks);
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = files.find(f => f.id === fileId)?.name || 'download';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                
                // Clear progress after delay
                setTimeout(() => {
                    delete downloadProgress[fileId];
                    updateDownloadUI(fileId);
                    loadFiles(); // Refresh to update download count
                }, 1000);
                
            } catch (error) {
                console.error('Download failed:', error);
                alert('Download failed. Please try again.');
                delete downloadProgress[fileId];
                updateDownloadUI(fileId);
            }
        }

        function updateDownloadUI(fileId) {
            const btn = document.querySelector('#file-' + fileId + ' .download-btn');
            const progressBar = document.getElementById('progress-' + fileId);
            const progressFill = progressBar?.querySelector('.progress-fill');
            
            if (btn) {
                if (downloadProgress[fileId]) {
                    btn.classList.add('downloading');
                    btn.textContent = '⏳';
                    progressBar?.classList.add('active');
                    if (progressFill) {
                        progressFill.style.width = (downloadProgress[fileId] * 100) + '%';
                    }
                } else {
                    btn.classList.remove('downloading');
                    btn.textContent = '⬇️';
                    progressBar?.classList.remove('active');
                }
            }
        }

        // Load files on page load and refresh every 5 seconds
        loadFiles();
        setInterval(loadFiles, 5000);
    </script>
</body>
</html>
''';
    response.write(html);
    await response.close();
  }

  /// Serve file list as JSON
  Future<void> _serveFileList(HttpResponse response) async {
    response.headers.contentType = ContentType.json;
    response.statusCode = HttpStatus.ok;

    final List<Map<String, dynamic>> fileList = [];
    for (final f in _sharedFiles) {
      fileList.add({
        'id': f.id,
        'name': f.name,
        'size': f.size,
        'mimeType': f.mimeType,
        'downloadCount': _downloadCounts[f.id] ?? 0,
      });
    }

    response.write(jsonEncode(fileList));
    await response.close();
  }

  /// Serve file download with concurrent session tracking
  /// Supports multiple users downloading the same file simultaneously
  Future<void> _serveFileDownload(HttpRequest request, HttpResponse response, String fileId) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    
    // Check if we've hit the concurrent download limit
    if (_activeClients.length >= _maxConcurrentDownloads) {
      response.statusCode = HttpStatus.serviceUnavailable;
      response.write('Server busy. Too many concurrent downloads. Please try again in a moment.');
      await response.close();
      return;
    }

    final file = _sharedFiles.firstWhere(
      (f) => f.id == fileId,
      orElse: () => throw Exception('File not found'),
    );

    final filePath = _filePaths[fileId];
    if (filePath == null || !await File(filePath).exists()) {
      response.statusCode = HttpStatus.notFound;
      response.write('File not found');
      await response.close();
      return;
    }

    // Track this client
    final clientKey = '$clientIp:$fileId';
    _activeClients.add(clientKey);

    // Create download session
    final session = _DownloadSession(
      fileId: fileId,
      clientIp: clientIp,
    );
    _activeDownloads[fileId]?.add(session);

    // Increment download count
    _downloadCounts[fileId] = (_downloadCounts[fileId] ?? 0) + 1;

    // Parse range request for resume support
    final rangeHeader = request.headers.value('Range');
    int startByte = 0;
    int endByte = file.size - 1;
    bool isPartial = false;

    if (rangeHeader != null) {
      final rangeMatch = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (rangeMatch != null) {
        startByte = int.parse(rangeMatch.group(1)!);
        if (rangeMatch.group(2)!.isNotEmpty) {
          endByte = int.parse(rangeMatch.group(2)!);
        }
        isPartial = true;
      }
    }

    final contentLength = endByte - startByte + 1;

    // Set headers
    final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
    response.headers.contentType = ContentType.parse(mimeType);
    response.headers.set('Content-Disposition', 'attachment; filename="${file.name}"');
    response.headers.set('Accept-Ranges', 'bytes');
    response.headers.set('Cache-Control', 'no-cache');
    
    if (isPartial) {
      response.statusCode = HttpStatus.partialContent;
      response.headers.set('Content-Range', 'bytes $startByte-$endByte/${file.size}');
    } else {
      response.statusCode = HttpStatus.ok;
    }
    
    response.headers.set('Content-Length', '$contentLength');

    try {
      // Open file and seek to start position if needed
      final fileHandle = File(filePath).openSync();
      if (startByte > 0) {
        fileHandle.setPositionSync(startByte);
      }

      int sentBytes = 0;
      final bufferSize = 256 * 1024; // 256KB chunks for faster concurrent downloads
      
      while (sentBytes < contentLength) {
        final remainingBytes = contentLength - sentBytes;
        final chunkSize = remainingBytes < bufferSize ? remainingBytes : bufferSize;
        
        final chunk = fileHandle.readSync(chunkSize);
        if (chunk.isEmpty) break;
        
        response.add(chunk);
        sentBytes += chunk.length;
        session.bytesSent = sentBytes;
        
        // Update progress periodically
        if (sentBytes % (512 * 1024) == 0 || sentBytes >= contentLength) {
          final progress = sentBytes / contentLength;
          _downloadProgress[fileId]?.add(progress);
        }
        
        // Flush to send data immediately for better concurrent streaming
        await response.flush();
      }

      fileHandle.closeSync();
      session.isComplete = true;
      
      AppLogger.info('File download complete: ${file.name} for client $clientIp (${sentBytes} bytes)');
    } catch (e) {
      AppLogger.error('Error serving file download', e);
    } finally {
      _activeClients.remove(clientKey);
      _activeDownloads[fileId]?.remove(session);
      await response.close();
    }
  }

  /// Get active download count for a file
  int getActiveDownloadCount(String fileId) {
    return _activeDownloads[fileId]?.where((s) => !s.isComplete).length ?? 0;
  }

  /// Get total active download sessions
  int get totalActiveDownloads => _activeClients.length;

  /// Check if server has capacity for more downloads
  bool get hasDownloadCapacity => _activeClients.length < _maxConcurrentDownloads;

  /// Serve stats endpoint
  Future<void> _serveStats(HttpResponse response) async {
    response.headers.contentType = ContentType.json;
    response.statusCode = HttpStatus.ok;

    final stats = {
      'files': _sharedFiles.length,
      'downloads': _downloadCounts.values.fold(0, (a, b) => a + b),
      'serverTime': DateTime.now().toIso8601String(),
    };

    response.write(jsonEncode(stats));
    await response.close();
  }

  /// Get download progress stream for a file
  Stream<double>? getDownloadProgress(String fileId) {
    _downloadProgress[fileId] ??= StreamController<double>.broadcast();
    return _downloadProgress[fileId]!.stream;
  }

  /// Get file icon emoji based on extension
  String _getFileIconHtml(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    final icons = {
      'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️',
      'mp4': '🎬', 'mov': '🎬', 'avi': '🎬',
      'mp3': '🎵', 'wav': '🎵', 'flac': '🎵',
      'pdf': '📄', 'doc': '📝', 'docx': '📝', 'txt': '📝',
      'zip': '📦', 'rar': '📦', '7z': '📦',
      'apk': '📱', 'exe': '💻',
    };
    return icons[ext] ?? '📄';
  }

  /// Format file size for HTML display
  String _formatSizeHtml(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get server address
  String? get serverAddress => _serverAddress;

  /// Get server port
  int? get serverPort => _serverPort;

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get shared file count
  int get fileCount => _sharedFiles.length;

  /// Get total download count
  int get totalDownloads => _downloadCounts.values.fold(0, (a, b) => a + b);
}
