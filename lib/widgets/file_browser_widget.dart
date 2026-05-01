import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/file_item.dart';
import '../services/file_browser_service.dart';
import '../services/thumbnail_service.dart';

/// Widget for browsing files
class FileBrowserWidget extends StatefulWidget {
  final String initialPath;
  final Function(List<FileItem>) onFilesSelected;
  final bool multiSelect;
  final FileType? filterByType;

  const FileBrowserWidget({
    super.key,
    required this.initialPath,
    required this.onFilesSelected,
    this.multiSelect = true,
    this.filterByType,
  });

  @override
  State<FileBrowserWidget> createState() => _FileBrowserWidgetState();
}

class _FileBrowserWidgetState extends State<FileBrowserWidget> {
  late FileBrowserService _fileBrowserService;
  late ThumbnailService _thumbnailService;
  late String _currentPath;
  List<FileItem> _files = [];
  final List<FileItem> _selectedFiles = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fileBrowserService = FileBrowserService();
    _thumbnailService = ThumbnailService();
    _currentPath = widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    try {
      List<FileItem> files;

      if (_searchQuery.isNotEmpty) {
        files = await _fileBrowserService.searchFiles(
          _currentPath,
          _searchQuery,
        );
      } else {
        files = await _fileBrowserService.getFilesInDirectory(
          _currentPath,
          filterByType: widget.filterByType == null,
        );
      }

      // Filter by type if specified
      if (widget.filterByType != null) {
        files = files.where((f) => f.type == widget.filterByType).toList();
      }

      setState(() => _files = files);
    } catch (e) {
      debugPrint('Error loading files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDirectory(FileItem directory) {
    if (directory.isDirectory) {
      setState(() {
        _currentPath = directory.path;
        _selectedFiles.clear();
        _searchQuery = '';
      });
      _loadFiles();
    }
  }

  void _toggleFileSelection(FileItem file) {
    if (!file.isDirectory) {
      setState(() {
        if (_selectedFiles.contains(file)) {
          _selectedFiles.remove(file);
        } else {
          if (!widget.multiSelect) {
            _selectedFiles.clear();
          }
          _selectedFiles.add(file);
        }
      });
    }
  }

  void _goBack() {
    final parentPath = _currentPath.replaceAll(RegExp(r'/[^/]*$'), '');
    if (parentPath != _currentPath) {
      setState(() {
        _currentPath = parentPath;
        _selectedFiles.clear();
      });
      _loadFiles();
    }
  }

  void _confirmSelection() {
    if (_selectedFiles.isNotEmpty) {
      widget.onFilesSelected(_selectedFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildPathBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFileList(),
        ),
        if (_selectedFiles.isNotEmpty) _buildSelectionBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Files',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_files.length} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadFiles();
        },
        decoration: InputDecoration(
          hintText: 'Search files...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _loadFiles();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          if (_currentPath != '/storage/emulated/0')
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: 'Go back',
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                _currentPath,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No files found' : 'Empty folder',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) => _buildFileListItem(_files[index]),
    );
  }

  Widget _buildFileListItem(FileItem file) {
    final isSelected = _selectedFiles.contains(file);

    return ListTile(
      leading: _buildFileIcon(file),
      title: Text(file.name),
      subtitle: Text(
        file.isDirectory
            ? '${file.size} items'
            : '${_formatBytes(file.size)} • ${file.modified.toString().split('.')[0]}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: file.isDirectory
          ? const Icon(Icons.chevron_right)
          : widget.multiSelect
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleFileSelection(file),
            )
          : null,
      selected: isSelected,
      onTap: () {
        if (file.isDirectory) {
          _navigateToDirectory(file);
        } else {
          _toggleFileSelection(file);
        }
      },
    );
  }

  Widget _buildFileIcon(FileItem file) {
    if (file.isDirectory) {
      return const Icon(Icons.folder, color: Colors.blue);
    }

    switch (file.type) {
      case FileType.image:
        return FutureBuilder<Uint8List?>(
          future: _thumbnailService.getThumbnail(file.path),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  snapshot.data!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              );
            }
            return const Icon(Icons.image, color: Colors.purple);
          },
        );
      case FileType.video:
        return const Icon(Icons.video_file, color: Colors.red);
      case FileType.audio:
        return const Icon(Icons.audio_file, color: Colors.orange);
      case FileType.document:
        return const Icon(Icons.description, color: Colors.green);
      case FileType.archive:
        return const Icon(Icons.folder_zip, color: Colors.brown);
      case FileType.application:
        return const Icon(Icons.apps, color: Colors.indigo);
      case FileType.folder:
        return const Icon(Icons.folder, color: Colors.blue);
      case FileType.other:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedFiles.length} file${_selectedFiles.length == 1 ? '' : 's'} selected',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedFiles.clear()),
            child: const Text('Clear'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _confirmSelection,
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
