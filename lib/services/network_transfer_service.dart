import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/utils/logger.dart';

/// Resume marker for tracking partial transfers
class ResumeMarker {
  final String fileId;
  final int bytesTransferred;
  final DateTime timestamp;
  final String deviceId;

  ResumeMarker({
    required this.fileId,
    required this.bytesTransferred,
    required this.timestamp,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'bytesTransferred': bytesTransferred,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
  };

  factory ResumeMarker.fromJson(Map<String, dynamic> json) => ResumeMarker(
    fileId: json['fileId'] as String,
    bytesTransferred: json['bytesTransferred'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    deviceId: json['deviceId'] as String,
  );
}

/// Service for handling actual file transfers over TCP sockets with dynamic ports
/// Supports resumable transfers and concurrent connections
class NetworkTransferService {
  static final NetworkTransferService _instance = NetworkTransferService._internal();
  factory NetworkTransferService() => _instance;
  NetworkTransferService._internal();

  ServerSocket? _serverSocket;
  final Map<String, Socket> _activeConnections = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, ResumeMarker> _resumeMarkers = {};
  final ProgressTrackingService _progressService = ProgressTrackingService();

  // Port range for dynamic allocation
  static const int _minPort = 10000;
  static const int _maxPort = 65000;

  /// Save resume marker for a transfer
  void saveResumeMarker(String fileId, int bytesTransferred, String deviceId) {
    _resumeMarkers[fileId] = ResumeMarker(
      fileId: fileId,
      bytesTransferred: bytesTransferred,
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );
    AppLogger.info('Resume marker saved: $fileId at $bytesTransferred bytes');
  }

  /// Get resume marker for a file
  ResumeMarker? getResumeMarker(String fileId) {
    return _resumeMarkers[fileId];
  }

  /// Clear resume marker
  void clearResumeMarker(String fileId) {
    _resumeMarkers.remove(fileId);
  }

  /// Check if transfer can be resumed
  bool canResume(String fileId, int totalBytes) {
    final marker = _resumeMarkers[fileId];
    if (marker == null) return false;
    
    // Check if marker is not too old (1 hour)
    final age = DateTime.now().difference(marker.timestamp);
    if (age > const Duration(hours: 1)) {
      clearResumeMarker(fileId);
      return false;
    }
    
    return marker.bytesTransferred < totalBytes;
  }

  /// Find and allocate an available dynamic port
  Future<int> allocateDynamicPort() async {
    final random = DateTime.now().millisecondsSinceEpoch;
    int attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      // Generate pseudo-random port in range
      final port = _minPort + (random + attempts) % (_maxPort - _minPort);
      
      try {
        // Try to bind to test if port is available
        final testSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await testSocket.close();
        AppLogger.info('Allocated dynamic port: $port');
        return port;
      } catch (e) {
        attempts++;
        continue;
      }
    }

    throw Exception('Could not find available port after $maxAttempts attempts');
  }

  /// Start listening for incoming file transfers
  Future<int> startServer({int? preferredPort}) async {
    try {
      // Use preferred port or allocate dynamic one
      final port = preferredPort ?? await allocateDynamicPort();
      
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );

      AppLogger.info('File transfer server started on port $port');

      _serverSocket!.listen(
        _handleIncomingConnection,
        onError: (error) {
          AppLogger.error('Server socket error', error);
        },
        onDone: () {
          AppLogger.info('Server socket closed');
        },
      );

      return port;
    } catch (e) {
      AppLogger.error('Failed to start transfer server', e);
      rethrow;
    }
  }

  /// Stop the transfer server
  Future<void> stopServer() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    for (final socket in _activeConnections.values) {
      await socket.close();
    }
    _activeConnections.clear();

    await _serverSocket?.close();
    _serverSocket = null;
    
    AppLogger.info('File transfer server stopped');
  }

  /// Handle incoming connection
  void _handleIncomingConnection(Socket socket) {
    final clientAddress = '${socket.remoteAddress.address}:${socket.remotePort}';
    AppLogger.info('Incoming connection from $clientAddress');

    _activeConnections[clientAddress] = socket;

    // Listen for file metadata first, then file data
    final buffer = BytesBuilder();
    bool headerReceived = false;
    FileMetadata? currentFile;
    int expectedBytes = 0;
    int receivedBytes = 0;
    IOSink? fileSink;

    final subscription = socket.listen(
      (data) async {
        if (!headerReceived) {
          // Try to parse header
          buffer.add(data);
          final bufferBytes = buffer.toBytes();
          
          // Look for header delimiter (\n\n)
          final headerEnd = _findHeaderEnd(bufferBytes);
          
          if (headerEnd != -1) {
            // Parse header
            final headerBytes = bufferBytes.sublist(0, headerEnd);
            final header = utf8.decode(headerBytes);
            
            try {
              final headerJson = jsonDecode(header) as Map<String, dynamic>;
              currentFile = FileMetadata.fromJson(headerJson);
              expectedBytes = currentFile!.size;
              
              AppLogger.info('Receiving file: ${currentFile!.name} ($expectedBytes bytes)');
              
              // Start progress tracking
              _progressService.startTracking(currentFile!.id, expectedBytes);
              
              // Create file sink
              final savePath = await _getSavePath(currentFile!.name);
              fileSink = File(savePath).openWrite();
              
              // Write any remaining data from buffer
              final remainingData = bufferBytes.sublist(headerEnd + 2);
              if (remainingData.isNotEmpty) {
                fileSink!.add(remainingData);
                receivedBytes += remainingData.length;
                _progressService.updateProgress(currentFile!.id, receivedBytes);
              }
              
              headerReceived = true;
              buffer.clear();
            } catch (e) {
              AppLogger.error('Failed to parse file header', e);
              socket.add(utf8.encode('ERROR: Invalid header\n'));
              await socket.close();
              return;
            }
          }
        } else {
          // Receiving file data
          fileSink?.add(data);
          receivedBytes += data.length;
          
          // Update progress
          _progressService.updateProgress(currentFile!.id, receivedBytes);
          
          // Check if complete
          if (receivedBytes >= expectedBytes) {
            await fileSink?.close();
            _progressService.completeTracking(currentFile!.id);
            
            // Send acknowledgment
            socket.add(utf8.encode('OK: File received\n'));
            await socket.close();
            
            AppLogger.info('File received successfully: ${currentFile!.name}');
          }
        }
      },
      onError: (error) {
        AppLogger.error('Socket error during transfer', error);
        _progressService.cancelTracking(currentFile?.id ?? '');
        fileSink?.close();
      },
      onDone: () {
        AppLogger.info('Connection closed from $clientAddress');
        _activeConnections.remove(clientAddress);
        
        if (!headerReceived || receivedBytes < expectedBytes) {
          _progressService.cancelTracking(currentFile?.id ?? '');
          fileSink?.close();
        }
      },
    );

    _subscriptions[clientAddress] = subscription;
  }

  /// Send file to a remote device with resume support
  Future<void> sendFile(
    String host,
    int port,
    FileMetadata file,
    String filePath, {
    Function(double progress, double speed)? onProgress,
    String? deviceId,
    bool allowResume = true,
  }) async {
    Socket? socket;
    
    try {
      // Check for resume marker
      int startByte = 0;
      if (allowResume && deviceId != null) {
        final marker = getResumeMarker(file.id);
        if (marker != null && marker.deviceId == deviceId) {
          startByte = marker.bytesTransferred;
          AppLogger.info('Resuming transfer from byte $startByte');
        }
      }

      // Connect to remote device
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 10));
      AppLogger.info('Connected to $host:$port for file transfer');

      // Send file metadata header with resume info
      final headerMap = {
        ...file.toJson(),
        'resumeFrom': startByte,
        'allowResume': allowResume,
      };
      final header = jsonEncode(headerMap);
      final headerBytes = utf8.encode(header);
      final delimiter = utf8.encode('\n\n');
      
      socket.add(headerBytes);
      socket.add(delimiter);
      await socket.flush();

      // Wait for ready signal from receiver
      final readyResponse = await socket.timeout(const Duration(seconds: 10)).first;
      final readyStr = utf8.decode(readyResponse);
      
      if (!readyStr.startsWith('READY')) {
        throw Exception('Receiver not ready: $readyStr');
      }

      // Read and send file in chunks starting from resume point
      final fileHandle = File(filePath).openSync();
      if (startByte > 0) {
        fileHandle.setPositionSync(startByte);
      }
      
      final fileLength = await File(filePath).length();
      int sentBytes = startByte;
      final stopwatch = Stopwatch()..start();
      final bufferSize = 256 * 1024; // 256KB chunks for faster transfer

      while (sentBytes < fileLength) {
        final remainingBytes = fileLength - sentBytes;
        final chunkSize = remainingBytes < bufferSize ? remainingBytes : bufferSize;
        
        final chunk = fileHandle.readSync(chunkSize);
        if (chunk.isEmpty) break;
        
        socket.add(chunk);
        sentBytes += chunk.length;
        
        // Save resume marker periodically (every 1MB)
        if (sentBytes % (1024 * 1024) == 0 && deviceId != null) {
          saveResumeMarker(file.id, sentBytes, deviceId);
        }
        
        // Calculate progress and speed
        final progress = sentBytes / fileLength;
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
        final speed = elapsedSeconds > 0 ? (sentBytes - startByte) / elapsedSeconds : 0.0;
        
        onProgress?.call(progress, speed);
        
        // Flush to send data immediately
        await socket.flush();
      }

      fileHandle.closeSync();
      await socket.flush();
      
      // Wait for final acknowledgment
      final response = await socket.timeout(const Duration(seconds: 30)).first;
      final responseStr = utf8.decode(response);
      
      if (responseStr.startsWith('OK')) {
        // Transfer complete - clear resume marker
        clearResumeMarker(file.id);
        AppLogger.info('File sent successfully: ${file.name}');
      } else {
        // Save resume marker for future retry
        if (deviceId != null) {
          saveResumeMarker(file.id, sentBytes, deviceId);
        }
        throw Exception('Transfer failed: $responseStr');
      }
    } catch (e) {
      // Save resume marker on failure for retry
      if (deviceId != null) {
        final currentBytes = _progressService.getProgress(file.id)?.transferredBytes ?? 0;
        if (currentBytes > 0) {
          saveResumeMarker(file.id, currentBytes, deviceId);
        }
      }
      AppLogger.error('File transfer failed', e);
      rethrow;
    } finally {
      await socket?.close();
    }
  }

  /// Send multiple files
  Future<void> sendFiles(
    String host,
    int port,
    List<MapEntry<FileMetadata, String>> files, {
    Function(int currentFile, int totalFiles, double fileProgress, double totalProgress)? onProgress,
  }) async {
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.key.size);
    int totalSentBytes = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i].key;
      final path = files[i].value;
      
      await sendFile(host, port, file, path, onProgress: (progress, speed) {
        final fileSentBytes = (progress * file.size).toInt();
        totalSentBytes += fileSentBytes;
        final totalProgress = totalSentBytes / totalBytes;
        
        onProgress?.call(i + 1, files.length, progress, totalProgress);
      });
    }
  }

  /// Find the end of header in byte array
  int _findHeaderEnd(Uint8List data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 10 && data[i + 1] == 10) {
        return i;
      }
    }
    return -1;
  }

  /// Get path to save received file
  Future<String> _getSavePath(String fileName) async {
    // For Windows, use Downloads folder
    if (Platform.isWindows) {
      final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads\\FluxShare';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return '$downloadsPath\\$fileName';
    }
    
    // For Android and others, use app documents directory
    final appDir = await Directory.systemTemp.createTemp('flux_share_');
    return '${appDir.path}/$fileName';
  }

  /// Check if server is running
  bool get isServerRunning => _serverSocket != null;

  /// Get current server port
  int? get serverPort => _serverSocket?.port;

  /// Get active connection count
  int get activeConnectionCount => _activeConnections.length;
}

/// Extension for FileMetadata serialization
extension FileMetadataJson on FileMetadata {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'mimeType': mimeType,
    'hash': hash,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  static FileMetadata fromJson(Map<String, dynamic> json) => FileMetadata(
    id: json['id'] as String,
    name: json['name'] as String,
    size: json['size'] as int,
    mimeType: json['mimeType'] as String,
    hash: json['hash'] as String,
    path: json['path'] as String?,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.now(),
  );
}
