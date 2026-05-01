import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/services/encryption_service.dart';
import 'package:flux/src/rust/api/crypto.dart' as rust_crypto;
import 'package:flux/providers/settings_provider.dart';
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

/// Service for network file transfers
class NetworkTransferService {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final EncryptionService _encryptionService = EncryptionService();
  final Ref? _ref;
  ServerSocket? _serverSocket;
  final Map<String, Socket> _activeConnections = {};
  final Map<String, ResumeMarker> _resumeMarkers = {};
  
  // Security limits to prevent memory exhaustion attacks
  static const int _maxChunkSize = 1024 * 1024; // 1MB max chunk size
  static const int _maxBufferSize = 10 * 1024 * 1024; // 10MB max buffer size
  
  // Connection notification stream (legacy - kept for compatibility)
  final _connectionController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onConnection => _connectionController.stream;

  NetworkTransferService([this._ref]);

  /// Save resume marker for a transfer
  Future<void> saveResumeMarker(String fileId, int bytesTransferred, String deviceId) async {
    final marker = ResumeMarker(
      fileId: fileId,
      bytesTransferred: bytesTransferred,
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );
    
    // Store in memory for immediate access
    _resumeMarkers[fileId] = marker;
    
    // Persist to shared preferences for app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      final markerData = {
        'fileId': marker.fileId,
        'bytesTransferred': marker.bytesTransferred,
        'timestamp': marker.timestamp.toIso8601String(),
        'deviceId': marker.deviceId,
      };
      await prefs.setString('resume_marker_$fileId', jsonEncode(markerData));
      AppLogger.info('Resume marker saved and persisted: $fileId at $bytesTransferred bytes');
    } catch (e) {
      AppLogger.warning('Failed to persist resume marker: $e');
    }
  }

  /// Get resume marker for a file
  ResumeMarker? getResumeMarker(String fileId) {
    return _resumeMarkers[fileId];
  }

  /// Clear resume marker
  Future<void> clearResumeMarker(String fileId) async {
    _resumeMarkers.remove(fileId);
    
    // Remove from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('resume_marker_$fileId');
      AppLogger.info('Resume marker cleared from memory and storage: $fileId');
    } catch (e) {
      AppLogger.warning('Failed to clear persistent resume marker: $e');
    }
  }

  /// Load resume markers from persistent storage
  Future<void> loadResumeMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('resume_marker_')).toList();
      
      for (final key in keys) {
        final markerJson = prefs.getString(key);
        if (markerJson != null) {
          try {
            final markerData = jsonDecode(markerJson) as Map<String, dynamic>;
            final marker = ResumeMarker(
              fileId: markerData['fileId'] as String,
              bytesTransferred: markerData['bytesTransferred'] as int,
              timestamp: DateTime.parse(markerData['timestamp'] as String),
              deviceId: markerData['deviceId'] as String,
            );
            
            // Check if marker is not too old (1 hour)
            final age = DateTime.now().difference(marker.timestamp);
            if (age <= const Duration(hours: 1)) {
              _resumeMarkers[marker.fileId] = marker;
              AppLogger.info('Loaded resume marker from storage: ${marker.fileId} at ${marker.bytesTransferred} bytes');
            } else {
              // Clear expired marker
              await prefs.remove(key);
              AppLogger.info('Cleared expired resume marker: ${marker.fileId}');
            }
          } catch (e) {
            AppLogger.warning('Failed to parse resume marker for key $key: $e');
            await prefs.remove(key); // Remove corrupted marker
          }
        }
      }
      
      AppLogger.info('Loaded ${_resumeMarkers.length} resume markers from persistent storage');
    } catch (e) {
      AppLogger.error('Failed to load resume markers from storage: $e');
    }
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

  
  /// Start listening for incoming file transfers
  Future<int> startServer({int? preferredPort}) async {
    try {
      // Use preferred port or let OS assign an available port (0 = any available port)
      final port = preferredPort ?? 0;
      AppLogger.info('🔌 Binding server socket to port $port (preferred: $preferredPort)');

      // Try IPv6 first (dual-stack), fallback to IPv4
      ServerSocket? socket;
      try {
        socket = await ServerSocket.bind(
          InternetAddress.anyIPv6,
          port,
          shared: true,
          v6Only: false, // Allow both IPv4 and IPv6 connections
        );
        AppLogger.info('🌐 Bound to IPv6+IPv4 dual-stack on port ${socket.port}');
      } catch (e) {
        AppLogger.warning('IPv6 bind failed, falling back to IPv4: $e');
        socket = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
          shared: true,
        );
        AppLogger.info('📡 Bound to IPv4 only on port ${socket.port}');
      }
      
      _serverSocket = socket;
      final actualPort = socket.port;

      AppLogger.info('🌐 File transfer server successfully bound to port $actualPort');
      AppLogger.info('👂 Server listening for incoming connections...');

      _serverSocket!.listen(
        _handleIncomingConnection,
        onError: (error) {
          AppLogger.error('❌ Server socket error', error);
        },
        onDone: () {
          AppLogger.info('� Server socket closed');
        },
      );

      return actualPort; // Return the actual port the OS assigned
    } catch (e) {
      AppLogger.error('❌ Failed to start transfer server on port $preferredPort', e);
      rethrow;
    }
  }

  /// Stop the transfer server
  Future<void> stopServer() async {
    for (final socket in _activeConnections.values) {
      socket.destroy(); // Force immediate closure to break await for loops
    }
    _activeConnections.clear();

    await _serverSocket?.close();
    _serverSocket = null;

    AppLogger.info('File transfer server stopped');
  }

  /// Handle incoming connection with mandatory encryption
  void _handleIncomingConnection(Socket socket) {
    _processIncomingConnection(socket).catchError((e) {
      AppLogger.error('Unhandled error in connection', e);
    });
  }

  Future<void> _processIncomingConnection(Socket socket) async {
    final clientAddress =
        '${socket.remoteAddress.address}:${socket.remotePort}';
    AppLogger.info('Incoming encrypted connection from $clientAddress');

    _activeConnections[clientAddress] = socket;

    bool headerReceived = false;
    bool sessionKeyReceived = false;
    FileMetadata? currentFile;
    int expectedBytes = 0;
    int receivedBytes = 0;
    IOSink? fileSink;
    Uint8List? encryptionKey;

    final BytesBuilder incomingBuffer = BytesBuilder();

    try {
      await for (final data in socket) {
        incomingBuffer.add(data);
        
        final bufferBytes = incomingBuffer.toBytes();
        int offset = 0;
        bool processing = true;
        
        while (processing) {
          final remainingLength = bufferBytes.length - offset;
          
          if (!headerReceived) {
            final headerEnd = _findHeaderEnd(bufferBytes.sublist(offset));
            if (headerEnd != -1) {
              final headerBytes = bufferBytes.sublist(offset, offset + headerEnd);
              final header = utf8.decode(headerBytes);

              try {
                final headerJson = jsonDecode(header) as Map<String, dynamic>;
                
                if (headerJson['type'] == 'connection_handshake') {
                  AppLogger.info('🔗 Handshake from ${headerJson['deviceName']}');
                  final notification = {
                    'type': 'peer_connected',
                    'deviceCode': headerJson['deviceCode'],
                    'deviceName': headerJson['deviceName'],
                    'clientAddress': clientAddress,
                    'timestamp': DateTime.now().toIso8601String(),
                  };
                  _connectionController.add(notification);
                  socket.add(utf8.encode('HANDSHAKE_OK\n'));
                  await socket.flush();
                  await socket.close();
                  return;
                }

                currentFile = FileMetadata.fromJson(headerJson);
                expectedBytes = currentFile.size;
                
                if (!(headerJson['encrypted'] as bool? ?? true)) {
                  AppLogger.warning('Rejecting unencrypted transfer');
                  socket.add(utf8.encode('ERROR: Encryption required\n'));
                  await socket.close();
                  return;
                }

                AppLogger.info('Receiving: ${currentFile.name} ($expectedBytes bytes)');
                _progressService.startTracking(currentFile.id, expectedBytes);

                // Notify UI that a transfer has started
                _connectionController.add({
                  'type': 'transfer_started',
                  'file': currentFile.toJson(),
                });
                
                final savePath = await _getSavePath(currentFile.name);
                fileSink = File(savePath).openWrite();
                
                socket.add(utf8.encode('READY\n'));
                await socket.flush();

                offset += headerEnd + 2; // Consume header + \n\n
                headerReceived = true;
              } catch (e) {
                AppLogger.error('Header parse error', e);
                socket.add(utf8.encode('ERROR: Invalid header\n'));
                await socket.close();
                return;
              }
            } else {
              processing = false;
            }
          } else if (!sessionKeyReceived) {
            final keyPrefix = utf8.encode('KEY:');
            final newline = utf8.encode('\n');
            
            if (remainingLength > keyPrefix.length) {
              final searchBuffer = bufferBytes.sublist(offset);
              int keyStart = -1;
              for (int i = 0; i <= searchBuffer.length - keyPrefix.length; i++) {
                bool match = true;
                for (int j = 0; j < keyPrefix.length; j++) {
                  if (searchBuffer[i+j] != keyPrefix[j]) {
                    match = false;
                    break;
                  }
                }
                if (match) {
                  keyStart = i;
                  break;
                }
              }

              if (keyStart != -1) {
                int newlineIndex = -1;
                for (int i = keyStart + keyPrefix.length; i < searchBuffer.length; i++) {
                  if (searchBuffer[i] == newline[0]) {
                    newlineIndex = i;
                    break;
                  }
                }

                if (newlineIndex != -1) {
                  final keyBytes = searchBuffer.sublist(keyStart + keyPrefix.length, newlineIndex);
                  encryptionKey = base64Decode(utf8.decode(keyBytes));
                  sessionKeyReceived = true;
                  AppLogger.info('Session key received');
                  
                  offset += newlineIndex + 1;
                } else {
                  processing = false;
                }
              } else {
                processing = false;
              }
            } else {
              processing = false;
            }
          } else {
            const ivSize = 12;
            const tagSize = 16;
            const headerSize = 4;
            
            if (remainingLength < headerSize) {
              processing = false;
              break;
            }

            final chunkSize = ByteData.sublistView(Uint8List.fromList(bufferBytes.sublist(offset, offset + headerSize))).getUint32(0, Endian.big);
            final totalChunkSize = headerSize + ivSize + chunkSize + tagSize;

            if (remainingLength < totalChunkSize) {
              processing = false;
              break;
            }

            // Validate security limits
            if (chunkSize > _maxChunkSize) {
               AppLogger.error('Chunk size too large: $chunkSize');
               await socket.close();
               return;
            }

            final ivBytes = bufferBytes.sublist(offset + headerSize, offset + headerSize + ivSize);
            final encryptedData = bufferBytes.sublist(offset + headerSize + ivSize, offset + headerSize + ivSize + chunkSize);
            final tagBytes = bufferBytes.sublist(offset + headerSize + ivSize + chunkSize, offset + totalChunkSize);

            try {
              final encryptedWithTag = Uint8List(encryptedData.length + tagSize);
              encryptedWithTag.setAll(0, encryptedData);
              encryptedWithTag.setAll(encryptedData.length, tagBytes);

              final decrypted = await rust_crypto.decryptAesGcm(
                ciphertext: encryptedWithTag,
                key: encryptionKey!,
                nonce: ivBytes,
              );

              fileSink?.add(decrypted);
              receivedBytes += decrypted.length;
              _progressService.updateProgress(currentFile!.id, receivedBytes);

              offset += totalChunkSize;
              
              if (receivedBytes >= expectedBytes) {
                AppLogger.info('Transfer complete: ${currentFile.name}');
                await fileSink?.close();
                fileSink = null;
                _progressService.completeTracking(currentFile.id);

                // Notify UI that transfer is complete
                _connectionController.add({
                  'type': 'transfer_completed',
                  'fileId': currentFile.id,
                });

                socket.add(utf8.encode('OK: File received\n'));
                await socket.flush();
                processing = false;
              }
            } catch (e) {
              AppLogger.error('Decryption failed', e);
              processing = false;
            }
          }
        }
        
        // Cleanup buffer after processing
        if (offset > 0) {
          final remaining = bufferBytes.sublist(offset);
          incomingBuffer.clear();
          incomingBuffer.add(remaining);
        }
        
        // Additional security check for buffer size
        if (incomingBuffer.length > _maxBufferSize) {
           AppLogger.error('Buffer overflow detected');
           await socket.close();
           return;
        }
      }
    } catch (e) {
      AppLogger.error('Receive file error', e);
    } finally {
      AppLogger.info('Connection closed from $clientAddress');
      _activeConnections.remove(clientAddress);
      
      final shouldCancel = !headerReceived || !sessionKeyReceived || receivedBytes < expectedBytes;
      if (shouldCancel && currentFile != null) {
        _progressService.cancelTracking(currentFile.id);
      }

      await fileSink?.close();
      socket.destroy();
    }
  }

  /// Send file to a remote device with resume support and mandatory encryption
  /// All transfers are encrypted using AES-256-GCM for security
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
      // Encryption is mandatory for all transfers
      AppLogger.info('Starting encrypted file transfer: ${file.name}');

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
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
      final socketIterator = StreamIterator(socket);
      AppLogger.info('Connected to $host:$port for file transfer');

      // Send file metadata header with resume info and encryption flag
      final headerMap = {
        ...file.toJson(),
        'resumeFrom': startByte,
        'allowResume': allowResume,
        'encrypted': true,
      };
      final header = jsonEncode(headerMap);
      final headerBytes = utf8.encode(header);
      final delimiter = utf8.encode('\n\n');

      socket.add(headerBytes);
      socket.add(delimiter);
      await socket.flush();

      // Wait for ready signal from receiver
      if (!await socketIterator.moveNext().timeout(const Duration(seconds: 10))) {
        throw Exception('Timeout waiting for READY');
      }
      final readyStr = utf8.decode(socketIterator.current);

      if (!readyStr.contains('READY')) {
        throw Exception('Receiver not ready: $readyStr');
      }

      // Generate session key for encryption — always required
      final sessionKey = await _encryptionService.generateSessionKey();
      final keyData = utf8.encode('KEY:$sessionKey\n');
      socket.add(keyData);
      await socket.flush();

      final fileLength = await File(filePath).length();
      int sentFileBytes = startByte;
      final stopwatch = Stopwatch()..start();
      const bufferSize = 256 * 1024; // 256 KB chunks

      // Fix 2: decode key ONCE before the loop — not 4000× for a 1 GB file
      final keyBytes = base64Decode(sessionKey);

      // Fix 1: openRead() is a true async stream — never blocks the UI thread
      final fileStream = File(filePath).openRead(startByte);

      await for (final rawChunk in fileStream) {
        // Stream may yield chunks larger than bufferSize — slice them
        int offset = 0;
        while (offset < rawChunk.length) {
          final end = (offset + bufferSize).clamp(0, rawChunk.length);
          final chunk = Uint8List.fromList(rawChunk.sublist(offset, end));
          offset = end;

          // Rust AES-256-GCM encrypt — SIMD accelerated
          final nonce = await rust_crypto.generateNonce(); // 12-byte GCM nonce
          final encryptedWithTag = await rust_crypto.encryptAesGcm(
            plaintext: chunk,
            key: keyBytes,
            nonce: nonce,
          );
          // Rust returns [ciphertext | 16-byte GCM tag]
          final encryptedData = encryptedWithTag.sublist(
            0,
            encryptedWithTag.length - 16,
          );
          final tagBytes = encryptedWithTag.sublist(
            encryptedWithTag.length - 16,
          );

          // Wire protocol: [4 B plaintext-size BE][12 B nonce][ciphertext][16 B tag]
          final sizeBytes = ByteData(4)..setUint32(0, chunk.length, Endian.big);

          // Fix 3: batch all adds, NO flush inside loop
          // Let the OS TCP stack manage Nagle / window scaling natively
          socket.add(sizeBytes.buffer.asUint8List());
          socket.add(nonce);
          socket.add(encryptedData);
          socket.add(tagBytes);

          sentFileBytes += chunk.length;

          // Periodic flush for backpressure (every 2 MB)
          if (sentFileBytes % (2 * 1024 * 1024) == 0) {
            await socket.flush();
          }

          // Save resume marker every 1 MB
          if (sentFileBytes % (1024 * 1024) == 0 && deviceId != null) {
            saveResumeMarker(file.id, sentFileBytes, deviceId);
          }

          final progress = sentFileBytes / fileLength;
          final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
          final speed = elapsedSeconds > 0
              ? (sentFileBytes - startByte) / elapsedSeconds
              : 0.0;
          onProgress?.call(progress, speed);
        }
      }

      // Single flush after all chunks — lets TCP batch everything efficiently
      await socket.flush();

      // Wait for final acknowledgment
      if (!await socketIterator.moveNext().timeout(const Duration(seconds: 30))) {
        throw Exception('Timeout waiting for OK');
      }
      final responseStr = utf8.decode(socketIterator.current);

      if (responseStr.contains('OK')) {
        // Transfer complete - clear resume marker
        clearResumeMarker(file.id);
        AppLogger.info('File sent successfully: ${file.name}');
      } else {
        // Save resume marker for future retry
        if (deviceId != null) {
          saveResumeMarker(file.id, sentFileBytes, deviceId);
        }
        throw Exception('Transfer failed: $responseStr');
      }
    } catch (e) {
      // Save resume marker on failure for retry
      if (deviceId != null) {
        final currentBytes =
            _progressService.getProgress(file.id)?.transferredBytes ?? 0;
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
    Function(
      int currentFile,
      int totalFiles,
      double fileProgress,
      double totalProgress,
    )?
    onProgress,
  }) async {
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.key.size);
    int totalSentBytes = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i].key;
      final path = files[i].value;

      final bytesSentBeforeThisFile = totalSentBytes;

      await sendFile(
        host,
        port,
        file,
        path,
        onProgress: (progress, speed) {
          final fileSentBytes = (progress * file.size).toInt();
          final currentTotalSentBytes = bytesSentBeforeThisFile + fileSentBytes;
          final totalProgress = totalBytes > 0
              ? currentTotalSentBytes / totalBytes
              : 0.0;

          onProgress?.call(i + 1, files.length, progress, totalProgress);
        },
      );

      totalSentBytes += file.size;
    }
  }

  /// Find the end of header in byte array
  /// Returns position of delimiter (handles both single newline for handshake and double newline for file headers)
  int _findHeaderEnd(Uint8List data) {
    // First check for single newline (handshake messages)
    for (int i = 0; i < data.length; i++) {
      if (data[i] == 10) { // LF (newline)
        return i;
      }
    }
    
    // Then check for double newline (file transfer headers)
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 10 && data[i + 1] == 10) {
        return i;
      }
    }
    return -1;
  }

  /// Get path to save received file
  Future<String> _getSavePath(String fileName) async {
    // Try to get custom download directory from settings
    String? customDir;
    if (_ref != null) {
      try {
        final settings = _ref.read(settingsProvider);
        customDir = settings.downloadDirectory;
      } catch (e) {
        AppLogger.warning('Could not read settings, using default directory');
      }
    }

    // If custom directory is set, use it
    if (customDir != null && customDir.isNotEmpty) {
      final dir = Directory(customDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final separator = Platform.isWindows ? '\\' : '/';
      return '$customDir$separator$fileName';
    }

    // For Windows, use Downloads/FluxShare folder as default
    if (Platform.isWindows) {
      final downloadsPath =
          '${Platform.environment['USERPROFILE']}\\Downloads\\FluxShare';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return '$downloadsPath\\$fileName';
    }

    // For Android, use Downloads/FluxShare folder
    if (Platform.isAndroid) {
      final downloadsPath = '/storage/emulated/0/Download/FluxShare';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return '$downloadsPath/$fileName';
    }

    // For other platforms, use app documents directory
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
