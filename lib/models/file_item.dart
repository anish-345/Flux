import 'dart:io';

/// Represents a file item in the browser
class FileItem {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final FileType type;
  final bool isDirectory;

  FileItem({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.type,
    required this.isDirectory,
  });

  /// Get file extension
  String get extension {
    if (isDirectory) return '';
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Get human-readable size
  String get sizeString {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get human-readable modified date
  String get modifiedString {
    final now = DateTime.now();
    final difference = now.difference(modified);

    if (difference.inDays == 0) {
      return 'Today ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${modified.month}/${modified.day}/${modified.year}';
    }
  }

  /// Create from File
  factory FileItem.fromFile(File file) {
    final stat = file.statSync();
    final name = file.path.split('/').last;
    final type = _getFileType(name);

    return FileItem(
      path: file.path,
      name: name,
      size: stat.size,
      modified: stat.modified,
      type: type,
      isDirectory: false,
    );
  }

  /// Create from Directory
  factory FileItem.fromDirectory(Directory dir) {
    final stat = dir.statSync();
    final name = dir.path.split('/').last;

    return FileItem(
      path: dir.path,
      name: name,
      size: 0,
      modified: stat.modified,
      type: FileType.folder,
      isDirectory: true,
    );
  }

  /// Get file type from extension
  static FileType _getFileType(String filename) {
    final ext = filename.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'avi', 'mkv', 'mov', 'flv', 'wmv'].contains(ext)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(ext)) {
      return FileType.audio;
    } else if ([
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(ext)) {
      return FileType.document;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return FileType.archive;
    } else if (['apk', 'exe', 'app'].contains(ext)) {
      return FileType.application;
    } else {
      return FileType.other;
    }
  }
}

/// File type enum
enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  application,
  folder,
  other,
}
