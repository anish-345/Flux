import 'package:flutter/material.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/widgets/app_card.dart';

class TransferProgressWidget extends StatelessWidget {
  final TransferStatus transfer;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const TransferProgressWidget({
    super.key,
    required this.transfer,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final progress = transfer.totalBytes > 0
        ? transfer.transferredBytes / transfer.totalBytes
        : 0.0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Name and Status Row
          Row(
            children: [
              // File Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(transfer.state).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(transfer.fileName),
                  color: _getStatusColor(transfer.state),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              
              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.fileName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(transfer.state),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          transfer.state.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(transfer.state),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Icon/Animation
              _buildStatusWidget(transfer.state),
            ],
          ),

          const SizedBox(height: 20),

          // Animated Progress Bar
          _AnimatedProgressBar(
            progress: progress,
            color: _getStatusColor(transfer.state),
            isActive: transfer.state == TransferState.inProgress,
          ),

          const SizedBox(height: 16),

          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Size info
              Text(
                '${_formatSize(transfer.transferredBytes)} / ${_formatSize(transfer.totalBytes)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              
              // Percentage
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),

          // Speed and Time (only show if in progress)
          if (transfer.state == TransferState.inProgress) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatSpeed(transfer.speed),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  if (transfer.remainingSeconds > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(transfer.remainingSeconds),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(),

          // Error Message
          if (transfer.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        transfer.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (transfer.state == TransferState.completed ||
        transfer.state == TransferState.failed ||
        transfer.state == TransferState.cancelled) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (transfer.state == TransferState.inProgress)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded, size: 18),
              label: const Text('Pause'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          )
        else if (transfer.state == TransferState.paused)
          Expanded(
            child: FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Resume'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
            ),
          ),
        if (transfer.state == TransferState.inProgress ||
            transfer.state == TransferState.paused)
          const SizedBox(width: 12),
        if (transfer.state == TransferState.inProgress ||
            transfer.state == TransferState.paused)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusWidget(TransferState state) {
    switch (state) {
      case TransferState.inProgress:
        return SizedBox(
          width: 28,
          height: 28,
          child: _AnimatedPulse(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
        );
      case TransferState.completed:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppTheme.successColor,
            size: 18,
          ),
        );
      case TransferState.failed:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            color: AppTheme.errorColor,
            size: 18,
          ),
        );
      case TransferState.paused:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pause_rounded,
            color: AppTheme.warningColor,
            size: 18,
          ),
        );
      case TransferState.cancelled:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.textDisabled.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cancel_outlined,
            color: AppTheme.textTertiary,
            size: 18,
          ),
        );
      default:
        return Icon(
          Icons.schedule_rounded,
          color: AppTheme.textTertiary,
          size: 24,
        );
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    final iconMap = {
      'jpg': Icons.image_rounded,
      'jpeg': Icons.image_rounded,
      'png': Icons.image_rounded,
      'gif': Icons.image_rounded,
      'mp4': Icons.video_file_rounded,
      'mov': Icons.video_file_rounded,
      'avi': Icons.video_file_rounded,
      'mp3': Icons.audio_file_rounded,
      'wav': Icons.audio_file_rounded,
      'pdf': Icons.picture_as_pdf_rounded,
      'doc': Icons.description_rounded,
      'docx': Icons.description_rounded,
      'txt': Icons.text_snippet_rounded,
      'zip': Icons.folder_zip_rounded,
      'rar': Icons.folder_zip_rounded,
      'apk': Icons.android_rounded,
      'exe': Icons.computer_rounded,
    };
    return iconMap[ext] ?? Icons.insert_drive_file_rounded;
  }

  Color _getStatusColor(TransferState state) {
    switch (state) {
      case TransferState.inProgress:
        return AppTheme.accentColor;
      case TransferState.completed:
        return AppTheme.successColor;
      case TransferState.failed:
        return AppTheme.errorColor;
      case TransferState.paused:
        return AppTheme.warningColor;
      case TransferState.cancelled:
        return AppTheme.textTertiary;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s remaining';
    if (seconds < 60) return '${seconds}s remaining';
    if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s remaining';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m remaining';
  }
}

/// Animated progress bar with gradient
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isActive;

  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // Background
            Container(
              width: double.infinity,
              color: AppTheme.surfaceVariant,
            ),
            
            // Progress fill with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: progress * MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Shimmer effect when active
            if (isActive && progress < 1.0)
              Positioned.fill(
                child: _ShimmerEffect(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer effect for active progress
class _ShimmerEffect extends StatefulWidget {
  final Color color;

  const _ShimmerEffect({required this.color});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                widget.color,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Animated pulse for in-progress indicator
class _AnimatedPulse extends StatefulWidget {
  final Widget child;

  const _AnimatedPulse({required this.child});

  @override
  State<_AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<_AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

