// lib/ui/player_screen.dart
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/constants.dart';

class PlayerScreen extends StatefulWidget {
  final String filePath;
  final String? title;

  const PlayerScreen({super.key, required this.filePath, this.title});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  bool _hasError = false;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = io.File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File not found at:\n${widget.filePath}');
      }

      // Open the file
      await _player.open(Media(widget.filePath));
      
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetail = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF0F172A), Colors.black],
                  radius: 1.5,
                ),
              ),
            ),
          ),

          // Player / loading / error
          Center(
            child: _hasError
                ? _ErrorState(detail: _errorDetail, path: widget.filePath)
                : Video(
                    controller: _controller,
                    controls: MaterialVideoControls,
                  ),
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 8, right: 16, bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Playing Video',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class _ErrorState extends StatelessWidget {
  final String? detail;
  final String? path;
  const _ErrorState({this.detail, this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text('Failed to play video',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'The file may be corrupt, missing, or use an unsupported codec.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          if (detail != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(detail!,
                  style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'monospace')),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentIndigo,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
