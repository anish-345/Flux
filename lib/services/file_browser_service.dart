import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_item.dart';

/// Service for browsing files
class FileBrowserService {
  static const List<String> _allowedExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', // Images
    'mp4', 'avi', 'mkv', 'mov', 'flv', 'wmv', // Videos
    'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', // Audio
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', // Documents
    'zip', 'rar', '7z', 'tar', 'gz', // Archives
    'txt', 'json', 'xml', 'csv', // Text
  ];

  /// Get files in directory
  Future<List<FileItem>> getFilesInDirectory(
    String path, {
    bool includeDirectories = true,
    bool filterByType = true,
  }) async {
    try {
      final dir = Directory(path);
      final entities = await dir.list().toList();

      final files = <FileItem>[];

      for (final entity in entities) {
        if (entity is File) {
          if (filterByType && !_isAllowedFile(entity.path)) {
            continue;
          }
          files.add(FileItem.fromFile(entity));
        } else if (entity is Directory && includeDirectories) {
          files.add(FileItem.fromDirectory(entity));
        }
      }

      // Sort by type, then by name
      files.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      return files;
    } catch (e) {
      debugPrint('Error getting files: $e');
      return [];
    }
  }

  /// Search files
  Future<List<FileItem>> searchFiles(
    String path,
    String query, {
    bool recursive = true,
  }) async {
    try {
      final dir = Directory(path);
      final results = <FileItem>[];

      await _searchRecursive(dir, query, results, recursive);

      return results;
    } catch (e) {
      debugPrint('Error searching files: $e');
      return [];
    }
  }

  /// Search recursively
  Future<void> _searchRecursive(
    Directory dir,
    String query,
    List<FileItem> results,
    bool recursive,
  ) async {
    try {
      final entities = await dir.list().toList();

      for (final entity in entities) {
        if (entity is File) {
          if (entity.path.contains(query)) {
            results.add(FileItem.fromFile(entity));
          }
        } else if (entity is Directory && recursive) {
          await _searchRecursive(entity, query, results, recursive);
        }
      }
    } catch (e) {
      // Silently skip directories we can't access
    }
  }

  /// Get recent files
  Future<List<FileItem>> getRecentFiles(String path, {int limit = 20}) async {
    try {
      final files = await getFilesInDirectory(path);

      // Sort by modified date (newest first)
      files.sort((a, b) => b.modified.compareTo(a.modified));

      return files.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent files: $e');
      return [];
    }
  }

  /// Get files by type
  Future<List<FileItem>> getFilesByType(
    String path,
    FileType type, {
    bool recursive = false,
  }) async {
    try {
      final files = await getFilesInDirectory(path);

      return files.where((f) => f.type == type).toList();
    } catch (e) {
      debugPrint('Error getting files by type: $e');
      return [];
    }
  }

  /// Check if file is allowed
  bool _isAllowedFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Get storage paths
  Future<Map<String, String>> getStoragePaths() async {
    try {
      return {
        'downloads': '/storage/emulated/0/Download',
        'documents': '/storage/emulated/0/Documents',
        'pictures': '/storage/emulated/0/Pictures',
        'videos': '/storage/emulated/0/Movies',
        'music': '/storage/emulated/0/Music',
      };
    } catch (e) {
      return {};
    }
  }
}
