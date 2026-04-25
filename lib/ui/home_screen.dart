// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/download_provider.dart';
import '../models/video_model.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String? _searchUrl;

  Future<void> _pasteAndSearch() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _urlController.text = text;
      setState(() => _searchUrl = text);
    }
  }

  void _onFetch() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid URL starting with http(s)://'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _searchUrl = url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white24 : Colors.black26;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName.toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2.0, 
                  fontSize: 24,
                  color: textColor),
            ),
            Text(
              AppConstants.appSubtitle,
              style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _pasteAndSearch,
            icon: const Icon(Icons.content_paste, color: AppConstants.accentIndigo),
            tooltip: 'Paste URL',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Adaptive Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: isDark 
                    ? [const Color(0xFF0F172A), Colors.black]
                    : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                  radius: 1.5,
                  center: Alignment.topLeft,
                ),
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
            child: Column(
              children: [
                // Hero
                Text(
                  'Capture Anything.',
                  textAlign: TextAlign.center,
                  style: textTheme.displayLarge?.copyWith(
                    color: textColor,
                    shadows: isDark ? [
                      const Shadow(color: Color(0x80C0C1FF), blurRadius: 12)
                    ] : [],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'High-fidelity downloads for your favorite cinematic content, instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppConstants.onSurfaceVariant : Colors.black45),
                ),
                const SizedBox(height: 48),

                // URL input
                GlassPanel(
                  borderRadius: 100.0,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.link, color: hintColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'Paste video URL here',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: hintColor),
                          ),
                          style: TextStyle(color: textColor),
                          onSubmitted: (_) => _onFetch(),
                        ),
                      ),
                      if (_urlController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _urlController.clear();
                            setState(() => _searchUrl = null);
                          },
                          icon: Icon(Icons.close, color: hintColor, size: 18),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppConstants.liquidGradient,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: ElevatedButton(
                          onPressed: _onFetch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100)),
                          ),
                          child: const Text('Fetch',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Results
                if (_searchUrl != null && _searchUrl!.isNotEmpty)
                  ref.watch(videoMetadataProvider(_searchUrl!)).when(
                    data: (video) => video != null
                        ? _VideoPreviewCard(
                            key: ValueKey(video.id), video: video)
                        : _ErrorWidget(
                            icon: Icons.search_off,
                            title: 'Video not found',
                            message:
                                'The URL returned no video. Check the link and try again.',
                            onClear: () =>
                                setState(() => _searchUrl = null),
                          ),
                    loading: () => Column(
                      children: [
                        const CircularProgressIndicator(
                            color: AppConstants.accentCyan),
                        const SizedBox(height: 16),
                        Text('Analyzing video…',
                            style: textTheme.labelMedium?.copyWith(color: textColor)),
                      ],
                    ),
                    error: (e, _) {
                      String msg = e.toString();
                      if (msg.contains('400') ||
                          msg.contains('yt_dlp') ||
                          msg.contains('Unsupported URL')) {
                        msg =
                            'Could not extract this video. It may be private, '
                            'age-restricted, or region-blocked. Try another link.';
                      }
                      return _ErrorWidget(
                        icon: Icons.wifi_off,
                        title: 'Extraction Failed',
                        message: msg,
                        onRetry: () {
                          final url = _searchUrl;
                          setState(() => _searchUrl = null);
                          Future.delayed(const Duration(milliseconds: 80),
                              () => setState(() => _searchUrl = url));
                        },
                        onClear: () => setState(() => _searchUrl = null),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video preview + quality selector ─────────────────────────────────────────

class _VideoPreviewCard extends ConsumerStatefulWidget {
  final VideoModel video;
  const _VideoPreviewCard({super.key, required this.video});

  @override
  ConsumerState<_VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends ConsumerState<_VideoPreviewCard> {
  VideoResolution? _selected;

  @override
  void initState() {
    super.initState();
    // Pre-select the highest quality by default
    if (widget.video.availableResolutions.isNotEmpty) {
      _selected = widget.video.availableResolutions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final resolutions = video.availableResolutions;
    final downloads = ref.watch(downloadQueueProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeTask = downloads.firstWhere(
      (t) =>
          t.title == video.title &&
          t.status != AppDownloadStatus.complete &&
          t.status != AppDownloadStatus.canceled &&
          t.status != AppDownloadStatus.failed,
      orElse: () => const DownloadTaskInfo(
          taskId: '', title: '', thumbnailUrl: ''),
    );
    final isDownloading = activeTask.taskId.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ──────────────────────────────────────────────────
          _Thumbnail(video: video),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quality grid ──────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'SELECT QUALITY',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.accentIndigo.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${resolutions.length} formats',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppConstants.accentIndigo,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (resolutions.isEmpty)
                  Text('No qualities found for this video.',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))
                else
                  _QualityGrid(
                    resolutions: resolutions,
                    selected: _selected,
                    onSelect: (r) => setState(() => _selected = r),
                  ),

                // ── Active download progress ──────────────────────────────
                if (isDownloading) ...[
                  const SizedBox(height: 28),
                  _DownloadProgress(task: activeTask),
                ],

                const SizedBox(height: 32),

                // ── Download button ───────────────────────────────────────
                _DownloadButton(
                  selected: _selected,
                  onTap: () {
                    if (_selected == null) return;
                    ref
                        .read(downloadQueueProvider.notifier)
                        .startDownload(video, _selected!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppConstants.accentCyan),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Downloading ${_selected!.label}…',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quality grid ──────────────────────────────────────────────────────────────

class _QualityGrid extends StatelessWidget {
  final List<VideoResolution> resolutions;
  final VideoResolution? selected;
  final ValueChanged<VideoResolution> onSelect;

  const _QualityGrid({
    required this.resolutions,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: resolutions.map((res) {
        final isSelected = selected?.label == res.label;
        final is4k = res.height >= 2160;
        final isHd = res.height >= 1080;
        final isMid = res.height >= 720;

        // Colour coding by tier
        Color accentColor;
        if (is4k) {
          accentColor = const Color(0xFFFF6B6B); // red — premium
        } else if (isHd) {
          accentColor = AppConstants.accentCyan;
        } else if (isMid) {
          accentColor = AppConstants.accentIndigo;
        } else {
          accentColor = isDark ? Colors.white38 : Colors.black38;
        }

        return GestureDetector(
          onTap: () => onSelect(res),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.18)
                  : (isDark ? const Color(0x0DFFFFFF) : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: accentColor.withOpacity(0.25),
                          blurRadius: 12)
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier icon
                _QualityIcon(res: res, color: isSelected ? accentColor : (isDark ? Colors.white24 : Colors.black26)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      res.label,
                      style: TextStyle(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black87) 
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    // Sub-labels: HDR / 60fps / needs merge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (res.isHdr)
                          _MicroBadge('HDR', const Color(0xFFFFD700)),
                        if (res.isHfr)
                          _MicroBadge('60fps', AppConstants.accentCyan),
                        if (res.needsFFmpeg)
                          _MicroBadge('MERGE', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QualityIcon extends StatelessWidget {
  final VideoResolution res;
  final Color color;
  const _QualityIcon({required this.res, required this.color});

  @override
  Widget build(BuildContext context) {
    if (res.height >= 2160) {
      return Icon(Icons.four_k_rounded, size: 18, color: color);
    } else if (res.height >= 1440) {
      return Icon(Icons.hd_rounded, size: 18, color: color);
    } else if (res.height >= 1080) {
      return Icon(Icons.high_quality_rounded, size: 18, color: color);
    } else if (res.height >= 720) {
      return Icon(Icons.videocam_rounded, size: 16, color: color);
    }
    return Icon(Icons.video_settings_rounded, size: 15, color: color);
  }
}

class _MicroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MicroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8, color: color, fontWeight: FontWeight.w800)),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final VideoModel video;
  const _Thumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: video.thumbnailUrl,
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
              height: 240,
              color: Colors.black12,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: AppConstants.accentCyan))),
          errorWidget: (_, __, ___) => Container(
              height: 240,
              color: Colors.black12,
              child: const Icon(Icons.movie, color: Colors.black26, size: 48)),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20, left: 20, right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video.title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${video.author} • ${AppConstants.formatDuration(video.duration)}',
                style:
                    const TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20, right: 20,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white30),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

// ── Download progress bar ─────────────────────────────────────────────────────

class _DownloadProgress extends ConsumerWidget {
  final DownloadTaskInfo task;
  const _DownloadProgress({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            children: [
              Container(
                height: 10, width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 10,
                width: constraints.maxWidth * (task.progress / 100),
                decoration: BoxDecoration(
                  gradient: AppConstants.liquidGradient,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                        color: AppConstants.accentCyan.withOpacity(0.4),
                        blurRadius: 8)
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
              'DOWNLOADING… ${task.progress}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 0.5),
            ),
            Text(
              '${AppConstants.formatBytes(task.speed.toInt())}/s '
              '• ${AppConstants.formatDuration(task.remainingTime)} left',
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _MiniBtn(
              icon: task.status == AppDownloadStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              onTap: () {
                if (task.status == AppDownloadStatus.paused) {
                  ref
                      .read(downloadQueueProvider.notifier)
                      .resumeTask(task.taskId);
                } else {
                  ref
                      .read(downloadQueueProvider.notifier)
                      .pauseTask(task.taskId);
                }
              },
            ),
            const SizedBox(width: 8),
            _MiniBtn(
              icon: Icons.stop_rounded,
              color: Colors.redAccent,
              onTap: () => ref
                  .read(downloadQueueProvider.notifier)
                  .cancelTask(task.taskId),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn(
      {required this.icon,
      this.color = AppConstants.accentCyan,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Download button ───────────────────────────────────────────────────────────

class _DownloadButton extends StatelessWidget {
  final VideoResolution? selected;
  final VoidCallback onTap;
  const _DownloadButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = selected != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: enabled ? AppConstants.liquidGradient : null,
        color: enabled ? null : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: enabled
            ? [
                BoxShadow(
                    color: AppConstants.accentCyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              enabled
                  ? 'Download  ${selected!.label}'
                  : 'Select a quality above',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: enabled ? Colors.white : (isDark ? Colors.white24 : Colors.black26)),
            ),
            const SizedBox(width: 12),
            Icon(Icons.download_for_offline_rounded,
                color: enabled ? Colors.white : (isDark ? Colors.white24 : Colors.black26)),
          ],
        ),
      ),
    );
  }
}

// ── Error widget ──────────────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onClear;

  const _ErrorWidget({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 48),
        const SizedBox(height: 16),
        Text(title,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            if (onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
          ],
        ),
      ],
    );
  }
}
