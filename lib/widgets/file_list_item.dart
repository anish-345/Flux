import 'package:flutter/material.dart';
import 'package:flux/models/file_metadata.dart';

class FileListItem extends StatelessWidget {
  final FileMetadata file;
  final VoidCallback? onSelect;
  final VoidCallback? onRemove;

  const FileListItem({
    super.key,
    required this.file,
    this.onSelect,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sizeInMB = (file.size / (1024 * 1024)).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _buildFileIcon(),
        title: Text(file.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$sizeInMB MB',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: onRemove != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                tooltip: 'Remove',
              )
            : null,
        onTap: onSelect,
      ),
    );
  }

  Widget _buildFileIcon() {
    final extension = file.mimeType.toLowerCase();

    if (extension.contains('image')) {
      return const Icon(Icons.image);
    } else if (extension.contains('video')) {
      return const Icon(Icons.video_file);
    } else if (extension.contains('audio')) {
      return const Icon(Icons.audio_file);
    } else if (extension.contains('pdf')) {
      return const Icon(Icons.picture_as_pdf);
    } else if (extension.contains('document') ||
        extension.contains('word') ||
        extension.contains('text')) {
      return const Icon(Icons.description);
    } else if (extension.contains('sheet') ||
        extension.contains('excel') ||
        extension.contains('csv')) {
      return const Icon(Icons.table_chart);
    } else if (extension.contains('presentation') ||
        extension.contains('powerpoint')) {
      return const Icon(Icons.slideshow);
    } else if (extension.contains('zip') ||
        extension.contains('rar') ||
        extension.contains('archive')) {
      return const Icon(Icons.folder_zip);
    } else if (extension.contains('folder') || file.isDirectory) {
      return const Icon(Icons.folder);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }
}
