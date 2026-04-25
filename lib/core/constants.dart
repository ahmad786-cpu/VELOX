// lib/core/constants.dart
import 'package:flutter/material.dart';

enum AppDownloadStatus {
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
}

class AppConstants {
  // ── Formatters ────────────────────────────────────────────────────────────
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = ((bytes.toString().length - 1) ~/ 3).clamp(0, suffixes.length - 1);
    return '${(bytes / (1 << (10 * i))).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '--:--';
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${two(d.inHours)}:$m:$s' : '$m:$s';
  }

  // ── App identity ──────────────────────────────────────────────────────────
  static const String appName          = 'Velox';
  static const String appSubtitle     = 'Premium Video Downloader';
  static const String downloadDirName  = 'Velox';
  static const String apiBaseUrl       = 'http://127.0.0.1:8000';

  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color background              = Color(0xFF0B1326);
  static const Color surface                 = Color(0xFF0B1326);
  static const Color surfaceContainer        = Color(0xFF171F33);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);

  static const Color primary          = Color(0xFFC0C1FF);
  static const Color secondary        = Color(0xFF4CD7F6);
  static const Color accentIndigo     = Color(0xFF6366F1);
  static const Color accentCyan       = Color(0xFF22D3EE);

  static const Color onBackground     = Color(0xFFDAE2FD);
  static const Color onSurface        = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFC7C4D7);

  // ── Gradient ──────────────────────────────────────────────────────────────
  static const LinearGradient liquidGradient = LinearGradient(
    colors: [accentIndigo, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double unit             = 8.0;
  static const double containerPadding = 24.0;
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double? opacity;
  final double? blur;
  final dynamic borderRadius; // Can be double or BorderRadius
  final EdgeInsetsGeometry? padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.opacity,
    this.blur,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final br = (borderRadius is num)
        ? BorderRadius.circular((borderRadius as num).toDouble())
        : (borderRadius as BorderRadius? ?? BorderRadius.circular(24));

    return ClipRRect(
      borderRadius: br,
      child: Stack(
        children: [
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(opacity ?? (isDark ? 0.05 : 0.02)),
              borderRadius: br,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                width: 0.5,
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: AppConstants.accentIndigo.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: child,
          ),
          // Luxury Reflection Streak
          if (!isDark)
            Positioned(
              top: -50,
              left: -50,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 100,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
