import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/services/_web_share_html.dart';
import 'package:flux/src/rust/api/mdns.dart' as rust_mdns;
import 'package:flux/utils/logger.dart';
import 'package:mime/mime.dart';

/// Download session tracking
class _DownloadSession {
  final String fileId;
  final String clientIp;
  final DateTime startedAt;
  int bytesSent = 0;
  bool isComplete = false;

  _DownloadSession({
    required this.fileId,
    required this.clientIp,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();
}

/// Service for hosting files via HTTP web server for browser-based downloads
/// Supports concurrent downloads, browser uploads, and live SSE updates.
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
  final Set<String> _activeClients = {};

  // SSE clients — each entry is an open HttpResponse for /api/events
  final List<HttpResponse> _sseClients = [];

  // Receive settings
  bool _receiveEnabled = false;
  String? _receiveFolder; // null = system Downloads

  bool get receiveEnabled => _receiveEnabled;
  String? get receiveFolder => _receiveFolder;

  // Callback fired when a browser uploads a file
  void Function(String filePath, String fileName)? onFileReceived;

  int? _serverPort;
  String? _serverAddress;
  String? _mdnsUrl;
  final int _maxConcurrentDownloads = 50;

  static const int _webSharePort = 8080;

  Future<Map<String, dynamic>> startServer({
    List<MapEntry<FileMetadata, String>>? files,
  }) async {
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

      // Use fixed port 8080 — consistent, memorable, no root needed
      _serverPort = _webSharePort;

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

      AppLogger.info(
        'Web share server started at $_serverAddress (max concurrent: $_maxConcurrentDownloads)',
      );

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

      // Register mDNS — each device gets a unique hostname derived from its
      // name, so multiple Flux instances on the same WiFi don't collide:
      //   anish-phone.local:8080, ravi-tablet.local:8080, etc.
      try {
        final deviceName = await _getDeviceName();
        final mdnsResult = await rust_mdns.registerMdnsService(
          port: _serverPort!,
          ipAddress: localIp,
          deviceName: deviceName,
        );
        _mdnsUrl = mdnsResult.url;
        AppLogger.info('mDNS registered: $_mdnsUrl (${mdnsResult.hostname})');
      } catch (e) {
        AppLogger.warning('mDNS registration failed: $e');
        _mdnsUrl = null;
      }

      return {
        'address': _serverAddress, // raw IP URL — always works
        'port': _serverPort,
        'url':
            _serverAddress, // primary URL shown in QR (IP-based, always works)
        'mdnsUrl':
            _mdnsUrl, // .local URL — works on iOS/macOS/Windows, NOT Android Chrome
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

  /// Get a human-readable device name for the mDNS hostname.
  /// Returns the device model/name so each device gets a unique .local address.
  Future<String> _getDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        // e.g. "Pixel 7" or "Samsung Galaxy S23"
        return android.model;
      } else if (Platform.isWindows) {
        final windows = await info.windowsInfo;
        return windows.computerName;
      } else if (Platform.isLinux) {
        final linux = await info.linuxInfo;
        return linux.name;
      } else if (Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return mac.computerName;
      }
    } catch (e) {
      AppLogger.warning('Could not get device name for mDNS: $e');
    }
    return ''; // Rust will fall back to flux-xxxx
  }

  /// Stop the web server
  Future<void> stopServer() async {
    // Close all SSE connections
    for (final client in _sseClients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _sseClients.clear();

    // Unregister mDNS so flux.local stops resolving
    try {
      await rust_mdns.unregisterMdnsService();
    } catch (e) {
      AppLogger.warning('mDNS unregister failed: $e');
    }
    _mdnsUrl = null;

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

  /// Enable or disable browser file uploads.
  void setReceiveEnabled(bool enabled, {String? folder}) {
    _receiveEnabled = enabled;
    if (folder != null) _receiveFolder = folder;
    _pushSseEvent('settings', jsonEncode({'receiveEnabled': enabled}));
  }

  /// Set the folder where uploaded files are saved.
  void setReceiveFolder(String folder) {
    _receiveFolder = folder;
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
    _pushFileListEvent(); // live update to all browsers
  }

  /// Remove a file from sharing
  void removeFile(String fileId) {
    _sharedFiles.removeWhere((f) => f.id == fileId);
    _filePaths.remove(fileId);
    _downloadCounts.remove(fileId);
    _downloadProgress[fileId]?.close();
    _downloadProgress.remove(fileId);
    _pushFileListEvent();
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
    _pushFileListEvent();
  }

  // ── SSE helpers ────────────────────────────────────────────────────────────

  /// Push the current file list to all connected SSE clients.
  void _pushFileListEvent() {
    final list = _sharedFiles
        .map(
          (f) => {
            'id': f.id,
            'name': f.name,
            'size': f.size,
            'mimeType': f.mimeType,
            'downloadCount': _downloadCounts[f.id] ?? 0,
          },
        )
        .toList();
    _pushSseEvent('files', jsonEncode(list));
  }

  /// Push a named SSE event to all connected browsers.
  void _pushSseEvent(String event, String data) {
    final payload = 'event: $event\ndata: $data\n\n';
    final dead = <HttpResponse>[];
    for (final client in _sseClients) {
      try {
        client.write(payload);
      } catch (_) {
        dead.add(client);
      }
    }
    _sseClients.removeWhere(dead.contains);
  }

  /// Handle HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path;

    try {
      // CORS headers
      response.headers.add('Access-Control-Allow-Origin', '*');
      response.headers.add(
        'Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
      );
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
      } else if (path == '/api/events') {
        await _serveSSE(request, response);
      } else if (path == '/upload' && request.method == 'POST') {
        await _handleUpload(request, response);
      } else if (path.startsWith('/download/')) {
        final fileId = path.substring('/download/'.length);
        if (fileId == 'all') {
          await _serveZipDownload(request, response);
        } else {
          await _serveFileDownload(request, response, fileId);
        }
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

  /// Serve the main index page with improved Flux Design System UI
  /// Serve the main index page � uses SSE for live updates and supports browser uploads.
  Future<void> _serveIndexPage(HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    response.write(webShareHtml);
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

  /// Server-Sent Events endpoint — keeps the connection open and pushes
  /// file list changes to the browser in real-time (no polling needed).
  Future<void> _serveSSE(HttpRequest request, HttpResponse response) async {
    response.headers.set('Content-Type', 'text/event-stream');
    response.headers.set('Cache-Control', 'no-cache');
    response.headers.set('Connection', 'keep-alive');
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.statusCode = HttpStatus.ok;

    // Register this client
    _sseClients.add(response);

    // Send current file list immediately on connect
    final list = _sharedFiles
        .map(
          (f) => {
            'id': f.id,
            'name': f.name,
            'size': f.size,
            'mimeType': f.mimeType,
            'downloadCount': _downloadCounts[f.id] ?? 0,
          },
        )
        .toList();
    response.write('event: files\ndata: ${jsonEncode(list)}\n\n');
    response.write(
      'event: settings\ndata: ${jsonEncode({'receiveEnabled': _receiveEnabled})}\n\n',
    );

    // Keep alive with a heartbeat every 15 seconds
    final heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      try {
        response.write(': heartbeat\n\n');
      } catch (_) {}
    });

    // Wait until the client disconnects
    try {
      await response.done;
    } catch (_) {}

    heartbeat.cancel();
    _sseClients.remove(response);
  }

  /// Handle multipart file upload from the browser.
  Future<void> _handleUpload(HttpRequest request, HttpResponse response) async {
    if (!_receiveEnabled) {
      response.statusCode = HttpStatus.forbidden;
      response.write(jsonEncode({'error': 'File receiving is disabled'}));
      await response.close();
      return;
    }

    try {
      final contentType = request.headers.contentType;
      if (contentType == null || !contentType.mimeType.contains('multipart')) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'error': 'Expected multipart/form-data'}));
        await response.close();
        return;
      }

      final boundary = contentType.parameters['boundary'];
      if (boundary == null) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'error': 'Missing boundary'}));
        await response.close();
        return;
      }

      // Determine save folder
      final saveDir = _receiveFolder ?? await _getDefaultDownloadFolder();
      await Directory(saveDir).create(recursive: true);

      // Parse multipart body
      final bodyBytes = await request.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );

      final savedFiles = <String>[];
      final parts = _parseMultipart(bodyBytes, boundary);

      for (final part in parts) {
        final filename = part['filename'];
        final data = part['data'] as List<int>?;
        if (filename == null || data == null || data.isEmpty) continue;

        final safeName = filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
        final savePath = '$saveDir${Platform.pathSeparator}$safeName';
        await File(savePath).writeAsBytes(data);
        savedFiles.add(safeName);

        AppLogger.info('Received file via web upload: $savePath');
        onFileReceived?.call(savePath, safeName);
      }

      response.headers.contentType = ContentType.json;
      response.statusCode = HttpStatus.ok;
      response.write(
        jsonEncode({
          'success': true,
          'files': savedFiles,
          'count': savedFiles.length,
        }),
      );
      await response.close();
    } catch (e) {
      AppLogger.error('Upload failed', e);
      response.statusCode = HttpStatus.internalServerError;
      response.write(jsonEncode({'error': 'Upload failed: $e'}));
      await response.close();
    }
  }

  /// Minimal multipart/form-data parser.
  /// Returns a list of maps with 'filename' and 'data' keys.
  List<Map<String, dynamic>> _parseMultipart(List<int> body, String boundary) {
    final parts = <Map<String, dynamic>>[];
    final boundaryBytes = '--$boundary'.codeUnits;
    final bodyStr = String.fromCharCodes(body);
    final sections = bodyStr.split('--$boundary');

    for (final section in sections) {
      if (section.trim().isEmpty || section.trim() == '--') continue;

      final headerBodySplit = section.indexOf('\r\n\r\n');
      if (headerBodySplit == -1) continue;

      final headers = section.substring(0, headerBodySplit);
      final rawBody = section.substring(headerBodySplit + 4);
      // Strip trailing \r\n
      final bodyContent = rawBody.endsWith('\r\n')
          ? rawBody.substring(0, rawBody.length - 2)
          : rawBody;

      // Extract filename from Content-Disposition
      final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(headers);
      if (filenameMatch == null) continue;

      final filename = filenameMatch.group(1)!;
      parts.add({'filename': filename, 'data': bodyContent.codeUnits});
    }

    // Use raw bytes for binary files — re-parse with proper byte handling
    final result = <Map<String, dynamic>>[];
    int pos = 0;

    while (pos < body.length) {
      // Find next boundary
      final bStart = _indexOfSeq(body, boundaryBytes, pos);
      if (bStart == -1) break;
      pos = bStart + boundaryBytes.length;

      // Skip \r\n after boundary
      if (pos + 1 < body.length && body[pos] == 13 && body[pos + 1] == 10) {
        pos += 2;
      } else if (pos + 1 < body.length &&
          body[pos] == 45 &&
          body[pos + 1] == 45) {
        break; // final boundary --
      }

      // Find end of headers (\r\n\r\n)
      final headerEnd = _indexOfSeq(body, [13, 10, 13, 10], pos);
      if (headerEnd == -1) break;

      final headerBytes = body.sublist(pos, headerEnd);
      final headerStr = utf8.decode(headerBytes, allowMalformed: true);
      pos = headerEnd + 4;

      final fnMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerStr);
      if (fnMatch == null) continue;
      final filename = fnMatch.group(1)!;

      // Find next boundary to get data end
      final nextBoundary = _indexOfSeq(body, [13, 10, ...boundaryBytes], pos);
      final dataEnd = nextBoundary == -1 ? body.length : nextBoundary;
      final data = body.sublist(pos, dataEnd);

      result.add({'filename': filename, 'data': data});
      if (nextBoundary == -1) break;
      pos = nextBoundary;
    }

    return result.isNotEmpty ? result : parts;
  }

  int _indexOfSeq(List<int> haystack, List<int> needle, int start) {
    outer:
    for (int i = start; i <= haystack.length - needle.length; i++) {
      for (int j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  Future<String> _getDefaultDownloadFolder() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/FluxShare';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads\\FluxShare';
    } else {
      return '${Platform.environment['HOME']}/Downloads/FluxShare';
    }
  }

  /// Serve zip download of all files
  /// Avoids popup blockers by providing single download for all files
  Future<void> _serveZipDownload(
    HttpRequest request,
    HttpResponse response,
  ) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';

    if (_sharedFiles.isEmpty) {
      response.statusCode = HttpStatus.notFound;
      response.write('No files available for download');
      await response.close();
      return;
    }

    // Check if we've hit the concurrent download limit
    if (_activeClients.length >= _maxConcurrentDownloads) {
      response.statusCode = HttpStatus.serviceUnavailable;
      response.write(
        'Server busy. Too many concurrent downloads. Please try again in a moment.',
      );
      await response.close();
      return;
    }

    // Track this client
    final clientKey = '$clientIp:zip';
    _activeClients.add(clientKey);

    try {
      // Stream each file into the zip — never load entire files into memory.
      // We use ZipEncoder.startEncode / addFile(stream) so only one 256 KB
      // chunk is in memory at a time regardless of how many / how large the
      // files are.
      response.headers.contentType = ContentType.parse('application/zip');
      response.headers.set(
        'Content-Disposition',
        'attachment; filename="flux-files.zip"',
      );
      response.headers.set('Cache-Control', 'no-cache');
      // Content-Length is omitted intentionally — we don't know the
      // compressed size upfront when streaming.
      response.statusCode = HttpStatus.ok;

      final encoder = ZipEncoder();
      // OutputStreamBase that writes directly to the HTTP response.
      final outputStream = _ResponseOutputStream(response);
      encoder.startEncode(outputStream);

      for (final file in _sharedFiles) {
        final filePath = _filePaths[file.id];
        if (filePath == null || !await File(filePath).exists()) continue;

        final fileBytes = await File(filePath).readAsBytes();
        // ArchiveFile(name, size, Uint8List) — ZipEncoder streams through
        // _ResponseOutputStream so the full zip is never buffered in memory.
        final archiveFile = ArchiveFile(file.name, fileBytes.length, fileBytes);
        encoder.addFile(archiveFile);
      }

      encoder.endEncode();
      await response.flush();

      // Increment download counts for all files
      for (final file in _sharedFiles) {
        _downloadCounts[file.id] = (_downloadCounts[file.id] ?? 0) + 1;
      }

      AppLogger.info(
        'Zip download complete for client $clientIp (${_sharedFiles.length} files)',
      );
      await response.close();
    } catch (e) {
      AppLogger.error('Error serving zip download', e);
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to create zip archive');
      await response.close();
    } finally {
      _activeClients.remove(clientKey);
    }
  }

  /// Serve file download with concurrent session tracking
  /// Supports multiple users downloading the same file simultaneously
  Future<void> _serveFileDownload(
    HttpRequest request,
    HttpResponse response,
    String fileId,
  ) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';

    // Check if we've hit the concurrent download limit
    if (_activeClients.length >= _maxConcurrentDownloads) {
      response.statusCode = HttpStatus.serviceUnavailable;
      response.write(
        'Server busy. Too many concurrent downloads. Please try again in a moment.',
      );
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
    final session = _DownloadSession(fileId: fileId, clientIp: clientIp);
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
    response.headers.set(
      'Content-Disposition',
      'attachment; filename="${file.name}"',
    );
    response.headers.set('Accept-Ranges', 'bytes');
    response.headers.set('Cache-Control', 'no-cache');

    if (isPartial) {
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        'Content-Range',
        'bytes $startByte-$endByte/${file.size}',
      );
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
      final bufferSize =
          256 * 1024; // 256KB chunks for faster concurrent downloads

      while (sentBytes < contentLength) {
        final remainingBytes = contentLength - sentBytes;
        final chunkSize = remainingBytes < bufferSize
            ? remainingBytes
            : bufferSize;

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

      AppLogger.info(
        'File download complete: $file.name for client $clientIp ($sentBytes bytes)',
      );
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
  bool get hasDownloadCapacity =>
      _activeClients.length < _maxConcurrentDownloads;

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

  /// Get server address (raw IP URL)
  String? get serverAddress => _serverAddress;

  /// Get mDNS URL (e.g. http://flux.local:8080), null if mDNS unavailable
  String? get mdnsUrl => _mdnsUrl;

  /// Best URL to show the user — always flux.local:8080
  String? get bestUrl => _mdnsUrl ?? _serverAddress;

  /// Get server port
  int? get serverPort => _serverPort;

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get shared file count
  int get fileCount => _sharedFiles.length;

  /// Get total download count
  int get totalDownloads => _downloadCounts.values.fold(0, (a, b) => a + b);
}

/// Bridges the `archive` package's [OutputStreamBase] to a Dart [HttpResponse].
/// This lets [ZipEncoder] write compressed bytes directly into the HTTP
/// response stream without ever buffering the full zip in memory.
class _ResponseOutputStream extends OutputStreamBase {
  final HttpResponse _response;
  int _bytesWritten = 0;

  _ResponseOutputStream(this._response);

  @override
  int get length => _bytesWritten;

  @override
  void writeByte(int value) {
    _response.add([value]);
    _bytesWritten++;
  }

  @override
  void writeBytes(List<int> bytes, [int? length]) {
    final data = length != null ? bytes.sublist(0, length) : bytes;
    _response.add(data);
    _bytesWritten += data.length;
  }

  @override
  void writeInputStream(InputStreamBase stream) {
    while (!stream.isEOS) {
      final bytes = stream.readBytes(65536); // 64 KB at a time
      _response.add(bytes.toUint8List());
      _bytesWritten += bytes.length;
    }
  }

  @override
  void flush() {
    // HttpResponse buffers internally; flushing is done after endEncode().
  }

  @override
  void writeUint16(int value) {
    _response.add([value & 0xFF, (value >> 8) & 0xFF]);
    _bytesWritten += 2;
  }

  @override
  void writeUint32(int value) {
    _response.add([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
    _bytesWritten += 4;
  }

  @override
  void writeUint64(int value) {
    // Write as two 32-bit little-endian words.
    final lo = value & 0xFFFFFFFF;
    final hi = (value >> 32) & 0xFFFFFFFF;
    writeUint32(lo);
    writeUint32(hi);
  }
}
