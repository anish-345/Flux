import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'base_service.dart';

/// Service for managing file operations
class FileService extends BaseService {
  static final FileService _instance = FileService._internal();

  factory FileService() {
    return _instance;
  }

  FileService._internal();

  /// Pick files from device
  Future<List<XFile>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      logInfo('Picking files...');

      // Build type groups for file_selector
      final typeGroups = allowedExtensions != null
          ? <XTypeGroup>[
              XTypeGroup(label: 'Files', extensions: allowedExtensions),
            ]
          : <XTypeGroup>[];

      final files = allowMultiple
          ? await openFiles(
              acceptedTypeGroups: typeGroups,
              initialDirectory: null,
            )
          : [
              await openFile(
                acceptedTypeGroups: typeGroups,
                initialDirectory: null,
              ),
            ].whereType<XFile>().toList();

      if (files.isNotEmpty) {
        logInfo('Picked ${files.length} file(s)');
        return files;
      }
      return null;
    } catch (e) {
      logError('Failed to pick files', e);
      return null;
    }
  }

  /// Get application documents directory
  Future<Directory> getAppDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      logDebug('App documents directory: ${directory.path}');
      return directory;
    } catch (e) {
      logError('Failed to get app documents directory', e);
      rethrow;
    }
  }

  /// Get application cache directory
  Future<Directory> getAppCacheDirectory() async {
    try {
      final directory = await getApplicationCacheDirectory();
      logDebug('App cache directory: ${directory.path}');
      return directory;
    } catch (e) {
      logError('Failed to get app cache directory', e);
      rethrow;
    }
  }

  /// Get application support directory
  Future<Directory> getAppSupportDirectory() async {
    try {
      final directory = await getApplicationSupportDirectory();
      logDebug('App support directory: ${directory.path}');
      return directory;
    } catch (e) {
      logError('Failed to get app support directory', e);
      rethrow;
    }
  }

  /// Get downloads directory
  Future<Directory?> getDownloadsDirectory() async {
    try {
      final directory = await getDownloadsDirectory();
      logDebug('Downloads directory: ${directory?.path}');
      return directory;
    } catch (e) {
      logError('Failed to get downloads directory', e);
      return null;
    }
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();
      logDebug('File size: $size bytes');
      return size;
    } catch (e) {
      logError('Failed to get file size', e);
      return 0;
    }
  }

  /// Get MIME type from file path
  String? getMimeType(String filePath) {
    try {
      final mimeType = lookupMimeType(filePath);
      logDebug('MIME type for $filePath: $mimeType');
      return mimeType;
    } catch (e) {
      logError('Failed to get MIME type', e);
      return null;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      logDebug('File exists: $exists');
      return exists;
    } catch (e) {
      logError('Failed to check if file exists', e);
      return false;
    }
  }

  /// Create directory
  Future<Directory> createDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        logInfo('Directory created: $path');
      }
      return directory;
    } catch (e) {
      logError('Failed to create directory', e);
      rethrow;
    }
  }

  /// Delete file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logInfo('File deleted: $filePath');
      }
    } catch (e) {
      logError('Failed to delete file', e);
      rethrow;
    }
  }

  /// Copy file
  Future<File> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = await sourceFile.copy(destinationPath);
      logInfo('File copied from $sourcePath to $destinationPath');
      return destinationFile;
    } catch (e) {
      logError('Failed to copy file', e);
      rethrow;
    }
  }

  /// Move file
  Future<File> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = await sourceFile.rename(destinationPath);
      logInfo('File moved from $sourcePath to $destinationPath');
      return destinationFile;
    } catch (e) {
      logError('Failed to move file', e);
      rethrow;
    }
  }

  /// Get file name from path
  String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Get file extension
  String getFileExtension(String filePath) {
    final fileName = getFileName(filePath);
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }

  /// List files in directory
  Future<List<FileSystemEntity>> listFilesInDirectory(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        logWarning('Directory does not exist: $dirPath');
        return [];
      }

      final files = await directory.list().toList();
      logDebug('Found ${files.length} items in directory');
      return files;
    } catch (e) {
      logError('Failed to list files in directory', e);
      return [];
    }
  }

  /// Read file as bytes
  Future<List<int>> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      logDebug('Read ${bytes.length} bytes from file');
      return bytes;
    } catch (e) {
      logError('Failed to read file as bytes', e);
      rethrow;
    }
  }

  /// Write bytes to file
  Future<File> writeFileAsBytes(String filePath, List<int> bytes) async {
    try {
      final file = File(filePath);
      final result = await file.writeAsBytes(bytes);
      logDebug('Wrote ${bytes.length} bytes to file');
      return result;
    } catch (e) {
      logError('Failed to write bytes to file', e);
      rethrow;
    }
  }
}
