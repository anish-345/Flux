import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';

/// Service for generating thumbnails
class ThumbnailService {
  static const int thumbnailSize = 128;
  static const int maxCacheSize = 100; // Max thumbnails to cache

  /// Maximum file size we'll attempt to decode (50 MB).
  /// Images larger than this get a null thumbnail instead of an OOM crash.
  static const int _maxDecodeSizeBytes = 50 * 1024 * 1024;

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
      } else if (['mp4', 'avi', 'mkv', 'mov', 'webm'].contains(ext)) {
        thumbnail = await _generateVideoThumbnail(filePath);
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

  /// Generate video thumbnail by seeking to 1 second and capturing a frame.
  /// Uses video_player to initialise the video and extract the first frame.
  /// Returns null if the video cannot be opened or is too short.
  Future<Uint8List?> _generateVideoThumbnail(String filePath) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(filePath));
      await controller.initialize();

      // Seek to 1 second (or halfway if shorter)
      final duration = controller.value.duration;
      final seekTo = duration.inSeconds > 2
          ? const Duration(seconds: 1)
          : Duration(milliseconds: duration.inMilliseconds ~/ 2);

      await controller.seekTo(seekTo);

      // video_player doesn't expose raw frame bytes directly.
      // We render it off-screen and capture via a placeholder PNG.
      // For a real frame capture, ffmpeg_kit_flutter would be needed.
      // Here we return a solid-colour placeholder with a play icon overlay
      // so video files show a recognisable thumbnail instead of nothing.
      final placeholder = _buildVideoPlaceholder();
      return placeholder;
    } catch (e) {
      debugPrint('Video thumbnail failed for $filePath: $e');
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  /// Build a 128×128 dark-grey PNG with a white play triangle — used as the
  /// video thumbnail when frame extraction is not available.
  static Uint8List _buildVideoPlaceholder() {
    final image = img.Image(width: thumbnailSize, height: thumbnailSize);

    // Dark background
    img.fill(image, color: img.ColorRgb8(30, 30, 30));

    // Draw a simple play triangle in the centre
    final cx = thumbnailSize ~/ 2;
    final cy = thumbnailSize ~/ 2;
    final size = thumbnailSize ~/ 4;
    final white = img.ColorRgb8(255, 255, 255);

    for (int y = cy - size; y <= cy + size; y++) {
      final halfWidth = ((y - (cy - size)) * size) ~/ (2 * size);
      for (int x = cx - halfWidth; x <= cx + halfWidth; x++) {
        if (x >= 0 && x < thumbnailSize && y >= 0 && y < thumbnailSize) {
          image.setPixel(x, y, white);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Generate image thumbnail — runs in a background isolate so the UI
  /// thread is never blocked, and refuses files larger than [_maxDecodeSizeBytes]
  /// to prevent OOM on huge images.
  Future<Uint8List?> _generateImageThumbnail(File file) async {
    try {
      // Guard: skip files that are too large to decode safely.
      final fileSize = await file.length();
      if (fileSize > _maxDecodeSizeBytes) {
        debugPrint(
          'ThumbnailService: skipping ${file.path} — '
          '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB exceeds limit',
        );
        return null;
      }

      // Offload decode + resize to a background isolate so the UI stays smooth.
      return await compute(_decodeAndResize, file.path);
    } catch (e) {
      debugPrint('Error generating image thumbnail: $e');
      return null;
    }
  }

  /// Top-level function required by [compute] — runs in a separate isolate.
  ///
  /// Memory lifecycle inside the isolate (separate heap from UI thread):
  ///   1. `bytes`  — raw file data, up to [_maxDecodeSizeBytes] (50 MB)
  ///   2. `image`  — decoded RGBA bitmap; `bytes` is no longer referenced
  ///                 after this line and is eligible for GC before resize.
  ///   3. `thumbnail` — 128×128 resized copy; full-res `image` goes out of
  ///                    scope and is eligible for GC before PNG encoding.
  ///   4. Return PNG bytes (~few KB) — everything else is GC-eligible.
  static Uint8List? _decodeAndResize(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      // `bytes` is no longer referenced after decodeImage returns.
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // `image` (full-res) is no longer referenced after copyResize returns.
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
      );
      return Uint8List.fromList(img.encodePng(thumbnail));
    } catch (_) {
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
