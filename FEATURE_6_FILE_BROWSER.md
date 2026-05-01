# Feature 6: File Browser & Preview

**Estimated Time:** 12 hours  
**Priority:** 🟠 UX Enhancement (implement sixth)  
**Status:** Ready for Implementation

---

## 📋 Overview

This feature adds a comprehensive file browser with preview capabilities, thumbnail generation, and multi-select functionality for improved file selection experience.

### User Experience

**Before (Current):**
```
User: "Select file to send"
App: Shows basic file picker
User: Can't see file preview or thumbnails
```

**After (Enhanced):**
```
User: "Select files to send"
App: Shows file browser with thumbnails
User: Can preview files, select multiple, organize by type
```

---

## 🎯 Implementation Goals

1. ✅ Implement file browser
2. ✅ Add thumbnail generation
3. ✅ Implement file preview
4. ✅ Add multi-select
5. ✅ Add file filtering
6. ✅ Add file organization

---

## 📁 Files to Create

### 1. `lib/models/file_item.dart` (NEW)

```dart
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
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
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
```

### 2. `lib/services/file_browser_service.dart` (NEW)

```dart
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
```

### 3. `lib/services/thumbnail_service.dart` (NEW)

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service for generating thumbnails
class ThumbnailService {
  static const int thumbnailSize = 128;
  static const int maxCacheSize = 100; // Max thumbnails to cache
  
  final Map<String, Uint8List> _thumbnailCache = {};
  
  /// Get thumbnail for file
  Future<Uint8List?> getThumbnail(String filePath) async {
    // Check cache first
    if (_thumbnailCache.containsKey(filePath)) {
      return _thumbnailCache[filePath];
    }
    
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last.toLowerCase();
      
      Uint8List? thumbnail;
      
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
        thumbnail = await _generateImageThumbnail(file);
      } else if (['mp4', 'avi', 'mkv', 'mov'].contains(ext)) {
        // Video thumbnail would require video_player or ffmpeg
        // For now, return null
        thumbnail = null;
      }
      
      // Cache thumbnail
      if (thumbnail != null) {
        _cacheThumbnail(filePath, thumbnail);
      }
      
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
  
  /// Generate image thumbnail
  Future<Uint8List?> _generateImageThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
      );
      
      // Encode as PNG
      return Uint8List.fromList(img.encodePng(thumbnail));
    } catch (e) {
      debugPrint('Error generating image thumbnail: $e');
      return null;
    }
  }
  
  /// Cache thumbnail
  void _cacheThumbnail(String filePath, Uint8List thumbnail) {
    // Remove oldest if cache is full
    if (_thumbnailCache.length >= maxCacheSize) {
      final firstKey = _thumbnailCache.keys.first;
      _thumbnailCache.remove(firstKey);
    }
    
    _thumbnailCache[filePath] = thumbnail;
  }
  
  /// Clear cache
  void clearCache() {
    _thumbnailCache.clear();
  }
  
  /// Clear specific thumbnail
  void clearThumbnail(String filePath) {
    _thumbnailCache.remove(filePath);
  }
}
```

### 4. `lib/screens/file_browser_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../services/file_browser_service.dart';
import '../services/thumbnail_service.dart';

/// Screen for browsing files
class FileBrowserScreen extends ConsumerStatefulWidget {
  final Function(List<FileItem>) onFilesSelected;
  final bool multiSelect;
  
  const FileBrowserScreen({
    Key? key,
    required this.onFilesSelected,
    this.multiSelect = true,
  }) : super(key: key);
  
  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  late FileBrowserService _fileBrowserService;
  late ThumbnailService _thumbnailService;
  
  String _currentPath = '/storage/emulated/0';
  List<FileItem> _files = [];
  Set<String> _selectedFiles = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fileBrowserService = FileBrowserService();
    _thumbnailService = ThumbnailService();
    _loadFiles();
  }
  
  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    
    try {
      final files = await _fileBrowserService.getFilesInDirectory(_currentPath);
      setState(() => _files = files);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading files: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _navigateToDirectory(String path) {
    setState(() {
      _currentPath = path;
      _selectedFiles.clear();
    });
    _loadFiles();
  }
  
  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        if (!widget.multiSelect) {
          _selectedFiles.clear();
        }
        _selectedFiles.add(filePath);
      }
    });
  }
  
  void _confirmSelection() {
    final selectedItems = _files
        .where((f) => _selectedFiles.contains(f.path))
        .toList();
    
    widget.onFilesSelected(selectedItems);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Files'),
        subtitle: Text(_currentPath),
        actions: [
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_selectedFiles.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No files found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return _FileItemWidget(
                      file: file,
                      isSelected: _selectedFiles.contains(file.path),
                      thumbnailService: _thumbnailService,
                      onTap: () {
                        if (file.isDirectory) {
                          _navigateToDirectory(file.path);
                        } else {
                          _toggleFileSelection(file.path);
                        }
                      },
                      onLongPress: () {
                        if (!file.isDirectory) {
                          _toggleFileSelection(file.path);
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: _selectedFiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: _confirmSelection,
              child: const Icon(Icons.check),
            )
          : null,
    );
  }
}

/// File item widget
class _FileItemWidget extends StatelessWidget {
  final FileItem file;
  final bool isSelected;
  final ThumbnailService thumbnailService;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  
  const _FileItemWidget({
    required this.file,
    required this.isSelected,
    required this.thumbnailService,
    required this.onTap,
    required this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(file.name),
        subtitle: file.isDirectory
            ? null
            : Text('${file.sizeString} • ${file.modifiedString}'),
        trailing: file.isDirectory
            ? const Icon(Icons.chevron_right)
            : isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
  
  Widget _buildLeadingIcon() {
    if (file.isDirectory) {
      return const Icon(Icons.folder);
    }
    
    switch (file.type) {
      case FileType.image:
        return _buildThumbnail();
      case FileType.video:
        return const Icon(Icons.video_file);
      case FileType.audio:
        return const Icon(Icons.audio_file);
      case FileType.document:
        return const Icon(Icons.description);
      case FileType.archive:
        return const Icon(Icons.archive);
      case FileType.application:
        return const Icon(Icons.app_shortcut);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }
  
  Widget _buildThumbnail() {
    return FutureBuilder<Uint8List?>(
      future: thumbnailService.getThumbnail(file.path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          );
        }
        return const Icon(Icons.image);
      },
    );
  }
}
```

### 5. `lib/widgets/file_browser_widget.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../screens/file_browser_screen.dart';

/// Widget for file browser integration
class FileBrowserWidget extends StatelessWidget {
  final Function(List<FileItem>) onFilesSelected;
  final bool multiSelect;
  final String buttonLabel;
  
  const FileBrowserWidget({
    Key? key,
    required this.onFilesSelected,
    this.multiSelect = true,
    this.buttonLabel = 'Select Files',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileBrowserScreen(
              onFilesSelected: onFilesSelected,
              multiSelect: multiSelect,
            ),
          ),
        );
      },
      icon: const Icon(Icons.folder_open),
      label: Text(buttonLabel),
    );
  }
}
```

---

## 🔧 Integration Steps

### Step 1: Update pubspec.yaml

```yaml
dependencies:
  file_picker: ^5.3.0
  image: ^4.0.0
  cached_network_image: ^3.3.0
```

### Step 2: Add to File Transfer Screen

```dart
// In file_transfer_screen.dart

class FileTransferScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        FileBrowserWidget(
          onFilesSelected: (files) {
            // Handle selected files
            for (final file in files) {
              ref.read(fileTransferProvider.notifier).addFile(file);
            }
          },
          multiSelect: true,
          buttonLabel: 'Select Files to Send',
        ),
      ],
    );
  }
}
```

### Step 3: Add Permissions

```xml
<!-- In AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

---

## 📊 File Browser Features

| Feature | Status |
|---------|--------|
| File browsing | ✅ |
| Thumbnail generation | ✅ |
| Multi-select | ✅ |
| File preview | ✅ |
| File search | ✅ |
| File filtering | ✅ |
| Recent files | ✅ |
| File organization | ✅ |

---

## 🧪 Testing Scenarios

### Test 1: File Selection
```
1. Open file browser
2. Navigate to directory
3. Select single file
4. Verify file selected
5. Confirm selection
```

### Test 2: Multi-Select
```
1. Open file browser
2. Select multiple files
3. Verify all selected
4. Deselect one
5. Confirm selection
```

### Test 3: Thumbnail Generation
```
1. Open file browser
2. Navigate to image directory
3. Verify thumbnails load
4. Verify thumbnails cached
5. Navigate away and back
6. Verify thumbnails load from cache
```

---

## 💡 Key Benefits

✅ **User-Friendly** - Easy file selection  
✅ **Visual** - Thumbnails for images  
✅ **Efficient** - Multi-select support  
✅ **Fast** - Thumbnail caching  
✅ **Organized** - File filtering and search  

---

**Completion:** All 6 features are now documented and ready for implementation!
