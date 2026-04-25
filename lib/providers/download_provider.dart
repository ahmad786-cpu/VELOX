// lib/providers/download_provider.dart
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/constants.dart';
import '../models/video_model.dart';
import '../services/extractor_service.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';

// ── Service providers ────────────────────────────────────────────────────────

final extractorServiceProvider = Provider((ref) => ExtractorService());

final _sharedDownloadService = DownloadService();
final downloadServiceProvider =
    Provider<DownloadService>((ref) => _sharedDownloadService);

// ── Video metadata provider ──────────────────────────────────────────────────

final videoMetadataProvider =
    FutureProvider.family<VideoModel?, String>((ref, url) {
  return ref.read(extractorServiceProvider).fetchVideoMetadata(url);
});

class DownloadTaskInfo {
  final String taskId;
  final String title;
  final String thumbnailUrl;
  final int progress;           // 0-100
  final AppDownloadStatus status;
  final String? localPath;
  final int downloadedSize;     // bytes
  final int totalSize;          // bytes
  final double speed;           // bytes/s
  final Duration remainingTime;
  final String? url;
  final String? audioUrl;

  const DownloadTaskInfo({
    required this.taskId,
    required this.title,
    required this.thumbnailUrl,
    this.progress = 0,
    this.status = AppDownloadStatus.enqueued,
    this.localPath,
    this.downloadedSize = 0,
    this.totalSize = 0,
    this.speed = 0,
    this.remainingTime = Duration.zero,
    this.url,
    this.audioUrl,
  });

  DownloadTaskInfo copyWith({
    String? taskId,
    int? progress,
    AppDownloadStatus? status,
    String? localPath,
    int? downloadedSize,
    int? totalSize,
    double? speed,
    Duration? remainingTime,
    String? url,
    String? audioUrl,
  }) {
    return DownloadTaskInfo(
      taskId: taskId ?? this.taskId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      totalSize: totalSize ?? this.totalSize,
      speed: speed ?? this.speed,
      remainingTime: remainingTime ?? this.remainingTime,
      url: url ?? this.url,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DownloadNotifier extends Notifier<List<DownloadTaskInfo>> {
  ReceivePort? _port;

  @override
  List<DownloadTaskInfo> build() {
    _initIsolatePort();
    final saved = StorageService.getAllTasks();
    // Re-register urls so desktop resume works
    for (final t in saved) {
      if (t.url != null) {
        ref.read(downloadServiceProvider).setTaskUrl(t.taskId, t.url!);
      }
    }
    return saved;
  }

  // Listen to FlutterDownloader callbacks from its isolate (mobile only)
  void _initIsolatePort() {
    if (kIsWeb) return;
    if (!io.Platform.isAndroid && !io.Platform.isIOS) return;

    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(
        _port!.sendPort, 'downloader_send_port');

    _port!.listen((dynamic data) async {
      final String id = data[0] as String;
      final int statusInt = data[1] as int;
      final int progress = data[2] as int;

      // flutter_downloader status ints map to our enum
      const Map<int, AppDownloadStatus> statusMap = {
        0: AppDownloadStatus.undefined,
        1: AppDownloadStatus.enqueued,
        2: AppDownloadStatus.running,
        3: AppDownloadStatus.complete,
        4: AppDownloadStatus.failed,
        5: AppDownloadStatus.canceled,
        6: AppDownloadStatus.paused,
      };
      final status =
          statusMap[statusInt] ?? AppDownloadStatus.undefined;

      _updateTask(id, progress: progress, status: status);

      if (status == AppDownloadStatus.complete) {
        await _resolveLocalPathAndSave(id);
      }
    });

    ref.onDispose(() {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      _port?.close();
    });
  }

  Future<void> _resolveLocalPathAndSave(String taskId) async {
    try {
      // On mobile, query flutter_downloader for saved path
      // (We can't import it statically here so we use StorageService data)
      final existing =
          state.firstWhere((t) => t.taskId == taskId, orElse: () {
        return const DownloadTaskInfo(
            taskId: '', title: '', thumbnailUrl: '');
      });
      if (existing.taskId.isEmpty) return;

      final savePath = await ref.read(downloadServiceProvider).getDownloadPath();
      // Best-guess path; FlutterDownloader callback gives us fileName via taskId
      final guessedPath = p.join(savePath, '${existing.title}.mp4');

      _updateTask(taskId, localPath: guessedPath);
      _persist();
    } catch (e) {
      debugPrint('[DownloadNotifier] _resolveLocalPath error: $e');
    }
  }

  // ── Public actions ────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    state = [];
    await StorageService.clearAll();
  }

  Future<void> startDownload(VideoModel video, VideoResolution resolution) async {
    final localId = 'task_${DateTime.now().millisecondsSinceEpoch}';
    
    // Better sanitization: keep spaces/dashes, remove only illegal Windows chars
    String sanitized = video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '-').trim();
    if (sanitized.length > 120) sanitized = sanitized.substring(0, 120);
    
    // Windows player (MF_MEDIA_ENGINE) hates .webm. Force .mp4 container.
    final ext = (!kIsWeb && io.Platform.isWindows) ? 'mp4' : resolution.ext;
    final fileName = '${sanitized}_${resolution.label}.$ext';

    // Insert placeholder immediately so UI updates
    final pending = DownloadTaskInfo(
      taskId: localId,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      status: AppDownloadStatus.enqueued,
      url: resolution.videoStreamUrl,
      audioUrl: resolution.audioStreamUrl,
    );
    state = [pending, ...state];
    _persist();

    String activeId = localId;

    try {
      final result = await ref.read(downloadServiceProvider).enqueueDownload(
        url: resolution.videoStreamUrl!,
        fileName: fileName,
        videoId: video.id,
        formatId: resolution.formatId,
        isMuxed: resolution.isMuxed,
        audioUrl: resolution.audioStreamUrl,
        onProgress: (prog, downloaded, total) {
          _updateTask(
            activeId,
            progress: prog,
            status: AppDownloadStatus.running,
            downloadedSize: downloaded,
            totalSize: total,
          );
        },
        onStatus: (status) {
          _updateTask(activeId, status: status);
          if (status == AppDownloadStatus.complete ||
              status == AppDownloadStatus.failed) {
            _persist();
          }
        },
      );

      if (result == null) {
        // Failed to enqueue
        _updateTask(localId, status: AppDownloadStatus.failed);
        _persist();
        return;
      }

      // result is a real taskId or file path
      final isPath = result.contains('/') ||
          result.contains('\\') ||
          result == 'web_download_started';

      activeId = result;

      if (isPath) {
        // Desktop / web — download started in background
        state = [
          for (final t in state)
            if (t.taskId == localId)
              t.copyWith(
                taskId: result,
                progress: 0,
                status: AppDownloadStatus.running,
                localPath: result == 'web_download_started' ? null : result,
                url: resolution.videoStreamUrl,
                audioUrl: resolution.audioStreamUrl,
              )
            else
              t
        ];
      } else {
        // FlutterDownloader task ID (mobile)
        state = [
          for (final t in state)
            if (t.taskId == localId)
              t.copyWith(
                taskId: result,
                status: AppDownloadStatus.enqueued,
                url: resolution.videoStreamUrl,
                audioUrl: resolution.audioStreamUrl,
              )
            else
              t
        ];
        ref.read(downloadServiceProvider).setTaskUrl(result, resolution.videoStreamUrl!);
      }
      _persist();
    } catch (e) {
      debugPrint('[DownloadNotifier] startDownload error: $e');
      _updateTask(localId, status: AppDownloadStatus.failed);
      _persist();
    }
  }

  Future<void> pauseTask(String taskId) async {
    await ref.read(downloadServiceProvider).pause(taskId);
    _updateTask(taskId, status: AppDownloadStatus.paused);
    _persist();
  }

  Future<void> resumeTask(String taskId) async {
    final task = state.firstWhere((t) => t.taskId == taskId,
        orElse: () =>
            const DownloadTaskInfo(taskId: '', title: '', thumbnailUrl: ''));
    await ref.read(downloadServiceProvider).resume(
      taskId,
      onProgress: (p, d, t) => _updateTask(
        taskId,
        progress: p,
        status: AppDownloadStatus.running,
        downloadedSize: d,
        totalSize: t,
      ),
    );
    _updateTask(taskId, status: AppDownloadStatus.running);
    _persist();
  }

  Future<void> cancelTask(String taskId) async {
    await ref.read(downloadServiceProvider).cancel(taskId);
    await StorageService.deleteTask(taskId);
    state = state.where((t) => t.taskId != taskId).toList();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  final _lastUpdateTime = <String, DateTime>{};
  final _lastSize = <String, int>{};

  void _updateTask(
    String taskId, {
    int? progress,
    AppDownloadStatus? status,
    String? localPath,
    int? downloadedSize,
    int? totalSize,
  }) {
    double speed = 0;
    Duration remaining = Duration.zero;

    if (downloadedSize != null && totalSize != null && totalSize > 0) {
      final now = DateTime.now();
      final lastT = _lastUpdateTime[taskId];
      final lastS = _lastSize[taskId];

      if (lastT != null && lastS != null) {
        final ms = now.difference(lastT).inMilliseconds;
        if (ms > 300) {
          speed = (downloadedSize - lastS) / ms * 1000; // bytes/s
          if (speed > 0) {
            final rem = totalSize - downloadedSize;
            remaining = Duration(seconds: (rem / speed).round());
          }
          _lastUpdateTime[taskId] = now;
          _lastSize[taskId] = downloadedSize;
        } else {
          final old = state.firstWhere((t) => t.taskId == taskId,
              orElse: () => const DownloadTaskInfo(
                  taskId: '', title: '', thumbnailUrl: ''));
          speed = old.speed;
          remaining = old.remainingTime;
        }
      } else {
        _lastUpdateTime[taskId] = now;
        _lastSize[taskId] = downloadedSize;
      }
    }

    state = [
      for (final t in state)
        if (t.taskId == taskId)
          t.copyWith(
            progress: progress == null
                ? null
                : progress.clamp(0, 100),
            status: status,
            localPath: localPath,
            downloadedSize: downloadedSize,
            totalSize: totalSize,
            speed: speed > 0 ? speed : null,
            remainingTime: remaining != Duration.zero ? remaining : null,
          )
        else
          t
    ];
  }

  void _persist() {
    for (final t in state) {
      StorageService.saveTask(t);
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final downloadQueueProvider =
    NotifierProvider<DownloadNotifier, List<DownloadTaskInfo>>(
        DownloadNotifier.new);
