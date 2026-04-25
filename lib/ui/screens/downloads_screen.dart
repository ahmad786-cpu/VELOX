import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/download_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_for_offline, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No downloads yet', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskItem(context, ref, task);
              },
            ),
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, DownloadTaskInfo task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: task.thumbnailUrl,
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.movie),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress / 100,
                    backgroundColor: Colors.white12,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${task.progress}% - ${_getStatusText(task.status)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      _buildActions(ref, task),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.enqueued: return 'Queued';
      case DownloadTaskStatus.downloading: return 'Downloading';
      case DownloadTaskStatus.paused: return 'Paused';
      case DownloadTaskStatus.complete: return 'Completed';
      case DownloadTaskStatus.failed: return 'Failed';
      case DownloadTaskStatus.canceled: return 'Canceled';
      case DownloadTaskStatus.undefined: return 'Unknown';
    }
  }

  Widget _buildActions(WidgetRef ref, DownloadTaskInfo task) {
    if (task.status == DownloadTaskStatus.complete) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    return Row(
      children: [
        if (task.status == DownloadTaskStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause, size: 20),
            onPressed: () => ref.read(downloadTasksProvider.notifier).pause(task.taskId),
          )
        else if (task.status == DownloadTaskStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 20),
            onPressed: () => ref.read(downloadTasksProvider.notifier).resume(task.taskId),
          ),
        IconButton(
          icon: const Icon(Icons.cancel, size: 20, color: Colors.redAccent),
          onPressed: () => ref.read(downloadTasksProvider.notifier).cancel(task.taskId),
        ),
      ],
    );
  }
}
