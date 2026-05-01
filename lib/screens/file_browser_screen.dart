import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../widgets/file_browser_widget.dart';

/// Screen for browsing and selecting files
class FileBrowserScreen extends StatelessWidget {
  final String initialPath;
  final bool multiSelect;
  final FileType? filterByType;

  const FileBrowserScreen({
    super.key,
    required this.initialPath,
    this.multiSelect = true,
    this.filterByType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Browser'), elevation: 0),
      body: FileBrowserWidget(
        initialPath: initialPath,
        multiSelect: multiSelect,
        filterByType: filterByType,
        onFilesSelected: (files) {
          Navigator.pop(context, files);
        },
      ),
    );
  }
}
