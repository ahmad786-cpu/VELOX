// lib/services/download_service.dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart' as fd;
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

import '../core/constants.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Referer': 'https://www.youtube.com/',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Origin': 'https://www.youtube.com',
      'Sec-Fetch-Mode': 'navigate',
      'Cookie': 'VISITOR_INFO1_LIVE=1; CONSENT=YES+cb.20210328-17-p0.en+FX+430',
    },
  ));

  final Map<String, String> _taskUrls = {};
  final Map<String, CancelToken> _cancelTokens = {};

  bool get _isMobile =>
      !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb || !_isMobile) return;
    try {
      await fd.FlutterDownloader.initialize(debug: false, ignoreSsl: true);
      fd.FlutterDownloader.registerCallback(_downloaderCallback);
      debugPrint('[DownloadService] FlutterDownloader ready');
    } catch (e) {
      debugPrint('[DownloadService] FlutterDownloader init error: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _downloaderCallback(String id, int status, int progress) {
    final SendPort? port =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    port?.send([id, status, progress]);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void setTaskUrl(String id, String url) => _taskUrls[id] = url;

  Future<String?> enqueueDownload({
    required String url,
    required String fileName,
    String? videoId,
    String? formatId,
    bool isMuxed = true,
    String? audioUrl,
    void Function(int progress, int downloaded, int total)? onProgress,
    void Function(AppDownloadStatus status)? onStatus,
  }) async {
    if (kIsWeb) {
      triggerWebDownload(url, fileName);
      return 'web_download_started';
    }

    final savedDir = await getDownloadPath();
    final outputPath = p.join(savedDir, fileName);

    // Windows with yt-dlp available -> Use the powerhouse
    if (!kIsWeb && io.Platform.isWindows && videoId != null && formatId != null) {
      _startDesktopYtDlpDownload(
        videoId: videoId,
        formatId: formatId,
        outputPath: outputPath,
        onProgress: onProgress,
        onStatus: onStatus,
      );
      return outputPath;
    }

    if (isMuxed) {
      if (_isMobile) {
        final taskId = await fd.FlutterDownloader.enqueue(
          url: url,
          savedDir: savedDir,
          fileName: fileName,
          showNotification: true,
          openFileFromNotification: false,
          saveInPublicStorage: false,
        );
        if (taskId != null) setTaskUrl(taskId, url);
        return taskId;
      } else {
        setTaskUrl(outputPath, url);
        _startDesktopDownload(url, outputPath,
            onProgress: onProgress, onStatus: onStatus);
        return outputPath;
      }
    } else {
      if (audioUrl == null) {
        debugPrint('[DownloadService] adaptive: audioUrl is null');
        return null;
      }
      // Start muxed download in background
      setTaskUrl(outputPath, url);
      _downloadAndMux(
        videoUrl: url,
        audioUrl: audioUrl,
        outputPath: outputPath,
        savedDir: savedDir,
        onProgress: onProgress,
        onStatus: onStatus,
      );
      return outputPath;
    }
  }

  Future<void> pause(String id) async {
    if (kIsWeb) return;
    if (_isMobile) {
      await fd.FlutterDownloader.pause(taskId: id);
    } else {
      _cancelTokens[id]?.cancel('pause');
    }
  }

  Future<void> resume(String id,
      {void Function(int, int, int)? onProgress}) async {
    if (kIsWeb) return;
    if (_isMobile) {
      await fd.FlutterDownloader.resume(taskId: id);
    } else {
      final url = _taskUrls[id];
      if (url != null) _startDesktopDownload(url, id, onProgress: onProgress);
    }
  }

  Future<void> cancel(String id) async {
    if (kIsWeb) return;
    _cancelTokens[id]?.cancel('cancel');
    _cancelTokens.remove(id);
    if (_isMobile) {
      await fd.FlutterDownloader.cancel(taskId: id);
    }
  }

  Future<String> getDownloadPath() async {
    if (kIsWeb) return '';

    if (io.Platform.isWindows) {
      try {
        final dDrive = io.Directory('D:\\');
        if (await dDrive.exists()) {
          final dir = io.Directory(r'D:\StreamVault');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir.path;
        } else {
          debugPrint('[DownloadService] D: drive not found, checking fallback');
        }
      } catch (e) {
        debugPrint('[DownloadService] D: drive check error: $e');
      }
    }

    // Fallback or Mobile path
    final base = await getApplicationDocumentsDirectory();
    final dir = io.Directory(p.join(base.path, AppConstants.downloadDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  // ── Desktop range-resume streaming ───────────────────────────────────────

  Future<String?> _startDesktopDownload(
    String url,
    String outputPath, {
    void Function(int, int, int)? onProgress,
    void Function(AppDownloadStatus)? onStatus,
    bool showStatus = true,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[outputPath] = cancelToken;

    try {
      final file = io.File(outputPath);
      final currentSize = await file.exists() ? await file.length() : 0;

      Response<ResponseBody> response;
      try {
        response = await _dio.get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers:
                currentSize > 0 ? {'Range': 'bytes=$currentSize-'} : null,
          ),
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 416) {
          await file.writeAsBytes([]);
          response = await _dio.get<ResponseBody>(
            url,
            options: Options(responseType: ResponseType.stream),
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }

      final cl = int.tryParse(
              response.headers.value('content-length') ?? '') ??
          -1;
      final totalBytes = cl == -1 ? -1 : cl + currentSize;
      final raf = await file.open(
          mode: currentSize > 0 ? io.FileMode.append : io.FileMode.write);
      int downloaded = currentSize;

      await for (final chunk in response.data!.stream) {
        await raf.writeFrom(chunk);
        downloaded += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(
            (downloaded / totalBytes * 100).clamp(0, 100).toInt(),
            downloaded,
            totalBytes,
          );
        }
      }
      await raf.close();
      _cancelTokens.remove(outputPath);
      if (showStatus) onStatus?.call(AppDownloadStatus.complete);
      return outputPath;
    } on DioException catch (e) {
      _cancelTokens.remove(outputPath);
      if (CancelToken.isCancel(e)) return outputPath; // resumable
      debugPrint('[DownloadService] Desktop download error: ${e.type} | ${e.message}');
      if (e.response != null) {
        debugPrint('[DownloadService] Status: ${e.response?.statusCode} | Data: ${e.response?.data}');
      }
      if (showStatus) onStatus?.call(AppDownloadStatus.failed);
      return null;
    } catch (e) {
      _cancelTokens.remove(outputPath);
      debugPrint('[DownloadService] Desktop unexpected error: $e');
      if (showStatus) onStatus?.call(AppDownloadStatus.failed);
      return null;
    }
  }

  // ── FFmpeg mux ────────────────────────────────────────────────────────────

  Future<String?> _downloadAndMux({
    required String videoUrl,
    required String audioUrl,
    required String outputPath,
    required String savedDir,
    void Function(int, int, int)? onProgress,
    void Function(AppDownloadStatus)? onStatus,
  }) async {
    final videoTmp = p.join(savedDir, '_v_${p.basename(outputPath)}');
    final audioTmp = p.join(savedDir, '_a_${p.basename(outputPath)}');
    final cancelToken = CancelToken();
    _cancelTokens[outputPath] = cancelToken;

    try {
      debugPrint('[DownloadService] Downloading video stream…');
      final videoResult = await _startDesktopDownload(
        videoUrl, 
        videoTmp, 
        onProgress: (p, d, t) => onProgress?.call((p * 0.8).toInt(), d, t),
        showStatus: false,
      );
      if (videoResult == null) throw Exception('Video download failed');

      debugPrint('[DownloadService] Downloading audio stream…');
      final audioResult = await _startDesktopDownload(
        audioUrl, 
        audioTmp, 
        onProgress: (p, d, t) => onProgress?.call(80 + (p * 0.15).toInt(), d, t),
        showStatus: false,
      );
      if (audioResult == null) throw Exception('Audio download failed');

      _cancelTokens.remove(outputPath);

      debugPrint('[DownloadService] Muxing…');
      onStatus?.call(AppDownloadStatus.running); 
      
      final vp = _fixPath(videoTmp);
      final ap = _fixPath(audioTmp);
      final op = _fixPath(outputPath);

      bool success = false;
      try {
        if (_isMobile || (!kIsWeb && io.Platform.isMacOS)) {
          final session = await FFmpegKit.execute(
              '-i "$vp" -i "$ap" -c copy -map 0:v:0 -map 1:a:0 "$op" -y');
          final rc = await session.getReturnCode();
          success = ReturnCode.isSuccess(rc);
        } else if (io.Platform.isWindows) {
          // Absolute path for Gyan.FFmpeg (WinGet)
          const ffmpegPath = r'C:\Users\Computer Arena\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe';
          
          // Use libx264 for maximum compatibility on Windows MF_MEDIA_ENGINE
          final result = await io.Process.run(ffmpegPath, [
            '-i', vp, '-i', ap,
            '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23',
            '-c:a', 'aac', '-map', '0:v:0', '-map', '1:a:0',
            op, '-y',
          ]);
          success = result.exitCode == 0;
          if (!success) {
            debugPrint('[DownloadService] ffmpeg failed: ${result.stderr}');
          }
        } else {
          // Linux / generic
          final result = await io.Process.run('ffmpeg', [
            '-i', vp, '-i', ap,
            '-c', 'copy', '-map', '0:v:0', '-map', '1:a:0',
            op, '-y',
          ]);
          success = result.exitCode == 0;
        }
      } catch (procErr) {
        debugPrint('[DownloadService] FFmpeg process error: $procErr');
        success = false;
      }

      if (success) {
        onProgress?.call(100, 1, 1);
        onStatus?.call(AppDownloadStatus.complete);
        return outputPath;
      } else {
        onStatus?.call(AppDownloadStatus.failed);
        return null;
      }
    } catch (e) {
      _cancelTokens.remove(outputPath);
      if (e is DioException) {
        debugPrint('[DownloadService] Mux Dio error: ${e.type} | ${e.message}');
        if (e.response != null) {
          debugPrint('[DownloadService] Mux Status: ${e.response?.statusCode} | Data: ${e.response?.data}');
        }
      } else {
        debugPrint('[DownloadService] Mux overall error: $e');
      }
      onStatus?.call(AppDownloadStatus.failed);
      return null;
    } finally {
      for (final tmp in [videoTmp, audioTmp]) {
        try {
          final f = io.File(tmp);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  // ── yt-dlp engine (The Ultimate Fix) ──────────────────────────────────
  
  Future<String?> _startDesktopYtDlpDownload({
    required String videoId,
    required String formatId,
    required String outputPath,
    void Function(int, int, int)? onProgress,
    void Function(AppDownloadStatus)? onStatus,
  }) async {
    const ytdlpPath = r'C:\Users\Computer Arena\AppData\Local\Python\pythoncore-3.14-64\Scripts\yt-dlp.exe';
    const ffmpegPath = r'C:\Users\Computer Arena\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe';
    
    try {
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      
      // We use -f formatId+bestaudio to get the best possible muxed quality.
      // We also use --ffmpeg-location to ensure it finds our specific ffmpeg.
      // Run yt-dlp directly WITHOUT runInShell to avoid path/space issues
      // We no longer need transcoding because MediaKit plays everything!
      final process = await io.Process.start(ytdlpPath, [
        '-f', '$formatId+bestaudio/best',
        '--ffmpeg-location', ffmpegPath,
        '--merge-output-format', 'mp4',
        '--newline',
        '--progress',
        '-o', outputPath,
        videoUrl,
      ], runInShell: false);

      onStatus?.call(AppDownloadStatus.running);

      bool isSecondPart = false;
      
      process.stdout.transform(io.systemEncoding.decoder).listen((line) {
        debugPrint('[yt-dlp stdout] $line');
        
        // Detect if we started the second part (Audio)
        if (line.contains('Destination:') && isSecondPart == false && line.contains('.f')) {
           // We've already seen one Destination, this is likely the second one
           isSecondPart = true;
        }

        // Detect Muxing/Merger phase
        if (line.contains('[Merger]') || line.contains('[VideoConvertor]') || line.contains('[Fixup]')) {
          onProgress?.call(98, 0, 0); // Almost done
          return;
        }

        // [download]  15.3% of ~10.23MiB at  2.45MiB/s ETA 00:04
        final reg = RegExp(r'\[download\]\s+(\d+\.?\d*)%\s+of\s+(?:~)?(\d+\.?\d*)(\w+)');
        final match = reg.firstMatch(line);
        if (match != null) {
          final percent = double.tryParse(match.group(1) ?? '0') ?? 0;
          final sizeVal = double.tryParse(match.group(2) ?? '0') ?? 0;
          final unit = match.group(3)?.toLowerCase() ?? 'mib';
          
          // Map to a unified 0-100 scale
          double unifiedPercent;
          if (!isSecondPart) {
            // Video is 0-85%
            unifiedPercent = percent * 0.85;
          } else {
            // Audio is 85-95%
            unifiedPercent = 85 + (percent * 0.10);
          }
          
          // Convert sizes
          double factor = 1024 * 1024;
          if (unit.contains('k')) factor = 1024;
          if (unit.contains('g')) factor = 1024 * 1024 * 1024;
          
          final totalBytes = (sizeVal * factor).toInt();
          final downloadedBytes = (totalBytes * (percent / 100)).toInt();
          
          onProgress?.call(unifiedPercent.toInt(), downloadedBytes, totalBytes);
        }
      });

      process.stderr.transform(io.systemEncoding.decoder).listen((line) {
        debugPrint('[yt-dlp stderr] $line');
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        onStatus?.call(AppDownloadStatus.complete);
        return outputPath;
      } else {
        onStatus?.call(AppDownloadStatus.failed);
        return null;
      }
    } catch (e) {
      debugPrint('[DownloadService] yt-dlp error: $e');
      onStatus?.call(AppDownloadStatus.failed);
      return null;
    }
  }

  String _fixPath(String path) =>
      (!kIsWeb && io.Platform.isWindows) ? path.replaceAll('/', '\\') : path;
}
