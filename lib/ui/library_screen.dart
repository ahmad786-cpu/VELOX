// lib/ui/library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/download_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'player_screen.dart';

final libraryViewProvider = StateProvider<bool>((ref) => true); // true = grid, false = list

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final isGrid = ref.watch(libraryViewProvider);
    
    final completed = tasks
        .where((t) => t.status == AppDownloadStatus.complete)
        .toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('YOUR VAULT',
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              letterSpacing: 2.0,
              color: textColor)),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, color: textColor),
            onPressed: () => ref.read(libraryViewProvider.notifier).state = !isGrid,
            tooltip: isGrid ? 'Switch to List' : 'Switch to Grid',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isActive: true),
                  _FilterChip(label: 'Videos'),
                  _FilterChip(label: 'Audio'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Downloaded',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: isDark ? AppConstants.primary : AppConstants.accentIndigo, fontWeight: FontWeight.bold)),
                Text('${completed.length} items', 
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            if (completed.isEmpty)
              const _EmptyVaultState()
            else if (isGrid)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: completed.length,
                itemBuilder: (ctx, i) =>
                    _VaultGridCard(task: completed[i]),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completed.length,
                itemBuilder: (ctx, i) =>
                    _VaultListCard(task: completed[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _FilterChip({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppConstants.liquidGradient : null,
        color: isActive ? null : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(100),
        border: isActive ? null : Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _VaultGridCard extends StatelessWidget {
  final DownloadTaskInfo task;
  const _VaultGridCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        if (task.localPath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                  filePath: task.localPath!, title: task.title),
            ),
          );
        }
      },
      child: GlassPanel(
        borderRadius: 24.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: task.thumbnailUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [AppConstants.accentIndigo.withOpacity(0.4), Colors.transparent],
                        radius: 0.7,
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_filled_rounded,
                        color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _SavedBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultListCard extends StatelessWidget {
  final DownloadTaskInfo task;
  const _VaultListCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (task.localPath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                    filePath: task.localPath!, title: task.title),
              ),
            );
          }
        },
        child: GlassPanel(
          borderRadius: 20.0,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: task.thumbnailUrl,
                  width: 100,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _SavedBadge(),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppConstants.accentCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('MP4', style: TextStyle(fontSize: 9, color: AppConstants.accentCyan, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        Icon(Icons.check_circle_rounded, color: isDark ? Colors.greenAccent : Colors.green, size: 12),
        const SizedBox(width: 4),
        Text('Saved', style: TextStyle(fontSize: 10, color: isDark ? Colors.greenAccent : Colors.green)),
      ],
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Opacity(
        opacity: 0.4,
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppConstants.accentIndigo.withOpacity(0.2),
                  AppConstants.accentCyan.withOpacity(0.2),
                ]),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: const Icon(Icons.video_library_rounded, size: 72, color: AppConstants.accentIndigo),
            ),
            const SizedBox(height: 24),
            Text('Vault is empty', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your collection starts here.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
