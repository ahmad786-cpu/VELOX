// lib/ui/downloads_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/download_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ACTIVE DOWNLOADS',
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.0,
              color: textColor)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: 'Clear all history',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: theme.cardTheme.color,
                  title: Text('Clear All Data?', style: TextStyle(color: textColor)),
                  content: Text(
                      'This will remove all download history from the list. It will NOT delete actual video files from your storage.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CANCEL',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(downloadQueueProvider.notifier).clearAll();
                        Navigator.pop(ctx);
                      },
                      child: const Text('CLEAR ALL',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: tasks.length,
              itemBuilder: (context, index) =>
                  _TaskCard(task: tasks[index]),
            ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final DownloadTaskInfo task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final isComplete = task.status == AppDownloadStatus.complete;
    final isPaused   = task.status == AppDownloadStatus.paused;
    final isRunning  = task.status == AppDownloadStatus.running;
    final isFailed   = task.status == AppDownloadStatus.failed;

    final borderColor = isComplete
        ? (isDark ? Colors.greenAccent : Colors.green)
        : isRunning
            ? AppConstants.accentCyan
            : isPaused
                ? Colors.orange
                : isFailed
                    ? Colors.redAccent
                    : (isDark ? Colors.white12 : Colors.black12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor.withOpacity(isDark ? 0.6 : 0.3), width: 1.5),
          boxShadow: isRunning
              ? [
                  BoxShadow(
                      color: AppConstants.accentCyan.withOpacity(isDark ? 0.15 : 0.08),
                      blurRadius: 20,
                      spreadRadius: -5)
                ]
              : null,
        ),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          borderRadius: 24.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: task.thumbnailUrl,
                      width: 80, height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 80, height: 50,
                        color: Colors.black12,
                        child: Icon(Icons.movie,
                            color: isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                        ),
                        const SizedBox(height: 4),
                        _StatusBadge(status: task.status),
                      ],
                    ),
                  ),
                ],
              ),

              // Progress bar (not for complete/failed/cancelled)
              if (isRunning || isPaused) ...[
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (ctx, constraints) => Stack(
                    children: [
                      Container(
                        height: 10, width: double.infinity,
                        decoration: BoxDecoration(
                            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(100)),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 10,
                        width: constraints.maxWidth * (task.progress / 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            isPaused
                                ? Colors.orange
                                : AppConstants.accentIndigo,
                            isPaused
                                ? Colors.deepOrange
                                : AppConstants.accentCyan,
                          ]),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                                color: (isPaused
                                        ? Colors.orange
                                        : AppConstants.accentCyan)
                                    .withOpacity(0.5),
                                blurRadius: 10)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${task.progress}%  •  '
                      '${AppConstants.formatBytes(task.downloadedSize)} / '
                      '${AppConstants.formatBytes(task.totalSize)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.bold),
                    ),
                    if (isRunning)
                      Text(
                        '${AppConstants.formatBytes(task.speed.toInt())}/s'
                        '  ${AppConstants.formatDuration(task.remainingTime)} left',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],

              // Completed info
              if (isComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: isDark ? Colors.greenAccent : Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text('Download complete',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.greenAccent : Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],

              // Failed info
              if (isFailed) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 6),
                    Text('Download failed',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRunning)
                    _NeonBtn(
                      icon: Icons.pause_rounded,
                      onTap: () => ref
                          .read(downloadQueueProvider.notifier)
                          .pauseTask(task.taskId),
                    ),
                  if (isPaused)
                    _NeonBtn(
                      icon: Icons.play_arrow_rounded,
                      onTap: () => ref
                          .read(downloadQueueProvider.notifier)
                          .resumeTask(task.taskId),
                    ),
                  if (isRunning || isPaused) ...[
                    const SizedBox(width: 10),
                    _NeonBtn(
                      icon: Icons.stop_rounded,
                      color: Colors.redAccent,
                      onTap: () => ref
                          .read(downloadQueueProvider.notifier)
                          .cancelTask(task.taskId),
                    ),
                  ],
                  if (isComplete && task.localPath != null) ...[
                    const SizedBox(width: 10),
                    _NeonBtn(
                      icon: Icons.ios_share_rounded,
                      onTap: () {
                        Share.shareXFiles(
                          [XFile(task.localPath!)],
                          text: task.title,
                        );
                      },
                    ),
                  ],
                  if (isComplete || isFailed) ...[
                    const SizedBox(width: 10),
                    _NeonBtn(
                      icon: Icons.delete_outline_rounded,
                      color: isDark ? Colors.white38 : Colors.black26,
                      onTap: () => ref
                          .read(downloadQueueProvider.notifier)
                          .cancelTask(task.taskId),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppDownloadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    String label;
    switch (status) {
      case AppDownloadStatus.running:
        color = AppConstants.accentCyan;
        label = 'Downloading';
        break;
      case AppDownloadStatus.paused:
        color = Colors.orange;
        label = 'Paused';
        break;
      case AppDownloadStatus.complete:
        color = isDark ? Colors.greenAccent : Colors.green;
        label = 'Complete';
        break;
      case AppDownloadStatus.failed:
        color = Colors.redAccent;
        label = 'Failed';
        break;
      case AppDownloadStatus.canceled:
        color = isDark ? Colors.white38 : Colors.black38;
        label = 'Cancelled';
        break;
      case AppDownloadStatus.enqueued:
        color = isDark ? Colors.white38 : Colors.black38;
        label = 'Queued';
        break;
      default:
        color = isDark ? Colors.white24 : Colors.black26;
        label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _NeonBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _NeonBtn(
      {required this.icon,
      this.color = AppConstants.accentCyan,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
          color: color.withOpacity(0.08),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Opacity(
        opacity: 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppConstants.accentIndigo.withOpacity(0.2),
                  AppConstants.accentCyan.withOpacity(0.2),
                ]),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: const Icon(Icons.download_for_offline,
                  size: 80, color: AppConstants.accentIndigo),
            ),
            const SizedBox(height: 24),
            Text('No active downloads',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your queue is currently empty.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
