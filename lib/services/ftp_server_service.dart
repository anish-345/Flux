import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/utils/logger.dart';

/// Simple FTP server for cross-network file transfers
/// Allows downloading files via FTP protocol from any network
class FtpServerService {
  static final FtpServerService _instance = FtpServerService._internal();
  factory FtpServerService() => _instance;
  FtpServerService._internal();

  ServerSocket? _serverSocket;
  final List<FileMetadata> _sharedFiles = [];
  final Map<String, String> _filePaths = {};
  final Map<String, Socket> _clients = {};

  int? _serverPort;
  bool _isRunning = false;

  /// Start FTP server with dynamic port
  Future<Map<String, dynamic>> startServer({List<MapEntry<FileMetadata, String>>? files}) async {
    try {
      await stopServer();

      if (files != null) {
        for (final entry in files) {
          _sharedFiles.add(entry.key);
          _filePaths[entry.key.id] = entry.value;
        }
      }

      // Use port 0 to let OS assign an available port
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign port
      );
      _serverPort = _serverSocket?.port ?? 0;

      _isRunning = true;
      AppLogger.info('FTP server started on port $_serverPort');

      _serverSocket!.listen(_handleClient);

      return {
        'port': _serverPort,
        'address': 'ftp://0.0.0.0:$_serverPort',
      };
    } catch (e) {
      AppLogger.error('Failed to start FTP server', e);
      rethrow;
    }
  }

  Future<void> stopServer() async {
    for (final client in _clients.values) {
      await client.close();
    }
    _clients.clear();
    await _serverSocket?.close();
    _serverSocket = null;
    _isRunning = false;
    _sharedFiles.clear();
    _filePaths.clear();
    AppLogger.info('FTP server stopped');
  }

  void addFiles(List<MapEntry<FileMetadata, String>> files) {
    for (final entry in files) {
      if (!_sharedFiles.any((f) => f.id == entry.key.id)) {
        _sharedFiles.add(entry.key);
        _filePaths[entry.key.id] = entry.value;
      }
    }
  }

  void _handleClient(Socket socket) {
    final clientId = '${socket.remoteAddress.address}:${socket.remotePort}';
    _clients[clientId] = socket;
    AppLogger.info('FTP client connected: $clientId');

    var session = _FtpSession(socket: socket);

    // Send welcome message
    _sendResponse(socket, '220 Welcome to Flux FTP Server\r\n');

    socket.listen(
      (data) => _processCommand(session, utf8.decode(data)),
      onError: (error) {
        AppLogger.error('FTP client error', error);
        _clients.remove(clientId);
      },
      onDone: () {
        AppLogger.info('FTP client disconnected: $clientId');
        _clients.remove(clientId);
      },
    );
  }

  void _processCommand(_FtpSession session, String commandLine) {
    commandLine = commandLine.trim();
    if (commandLine.isEmpty) return;

    final parts = commandLine.split(' ');
    final command = parts[0].toUpperCase();
    final argument = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    AppLogger.debug('FTP command: $command $argument');

    switch (command) {
      case 'USER':
        _sendResponse(session.socket, '331 Anonymous access allowed\r\n');
        break;
      case 'PASS':
        _sendResponse(session.socket, '230 Login successful\r\n');
        break;
      case 'SYST':
        _sendResponse(session.socket, '215 UNIX Type: L8\r\n');
        break;
      case 'FEAT':
        _sendResponse(session.socket, '211-Features:\r\n SIZE\r\n PASV\r\n211 End\r\n');
        break;
      case 'PWD':
      case 'CWD':
        _sendResponse(session.socket, '250 Directory changed\r\n');
        break;
      case 'TYPE':
        _sendResponse(session.socket, '200 Type set to I\r\n');
        break;
      case 'PASV':
        _enterPassiveMode(session);
        break;
      case 'LIST':
        _sendFileList(session);
        break;
      case 'SIZE':
        _sendFileSize(session, argument);
        break;
      case 'RETR':
        _downloadFile(session, argument);
        break;
      case 'QUIT':
        _sendResponse(session.socket, '221 Goodbye\r\n');
        session.socket.close();
        break;
      default:
        _sendResponse(session.socket, '502 Command not implemented\r\n');
    }
  }

  void _enterPassiveMode(_FtpSession session) {
    // Simple PASV implementation - just acknowledge
    _sendResponse(session.socket, '227 Entering Passive Mode (127,0,0,1,0,0)\r\n');
  }

  void _sendFileList(_FtpSession session) {
    final buffer = StringBuffer();
    buffer.write('125 Opening data connection\r\n');

    for (final file in _sharedFiles) {
      // UNIX-style listing: -rw-r--r-- 1 owner group size month day time filename
      final size = file.size.toString().padLeft(10);
      final date = 'Jan 01 00:00';
      buffer.write('-rw-r--r-- 1 ftp ftp $size $date ${file.name}\r\n');
    }

    buffer.write('226 Transfer complete\r\n');
    _sendResponse(session.socket, buffer.toString());
  }

  void _sendFileSize(_FtpSession session, String fileName) {
    final file = _sharedFiles.firstWhere(
      (f) => f.name == fileName,
      orElse: () => throw Exception('File not found'),
    );
    _sendResponse(session.socket, '213 ${file.size}\r\n');
  }

  void _downloadFile(_FtpSession session, String fileName) async {
    try {
      final file = _sharedFiles.firstWhere(
        (f) => f.name == fileName,
        orElse: () => throw Exception('File not found'),
      );

      final filePath = _filePaths[file.id];
      if (filePath == null || !File(filePath).existsSync()) {
        _sendResponse(session.socket, '550 File not found\r\n');
        return;
      }

      _sendResponse(session.socket, '150 Opening data connection\r\n');

      final fileData = await File(filePath).readAsBytes();
      session.socket.add(fileData);

      _sendResponse(session.socket, '226 Transfer complete\r\n');
      AppLogger.info('FTP download: ${file.name} (${file.size} bytes)');
    } catch (e) {
      AppLogger.error('FTP download error', e);
      _sendResponse(session.socket, '550 Failed to open file\r\n');
    }
  }

  void _sendResponse(Socket socket, String message) {
    socket.write(message);
  }

  bool get isRunning => _isRunning;
  int? get port => _serverPort;
}

class _FtpSession {
  final Socket socket;
  bool isPassive = false;

  _FtpSession({required this.socket});
}
