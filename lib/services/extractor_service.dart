// lib/services/extractor_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/video_model.dart';
import '../core/constants.dart';

class ExtractorService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  Future<VideoModel?> fetchVideoMetadata(String url) async {
    try {
      final response = await _dio.get(
        '/extract',
        queryParameters: {'url': url},
      );
      final data = response.data as Map<String, dynamic>;

      // ── top-level audio URL (best separate audio stream) ──────────────────
      final String? topAudioUrl = data['audio_url'] as String?;
      // ── build resolution list ─────────────────────────────────────────────
      final rawResolutions = (data['resolutions'] as List?) ?? [];
      final resolutions = <VideoResolution>[];

      for (final r in rawResolutions) {
        final resJson = r as Map<String, dynamic>;
        // Use the factory we added to ensure all fields (like formatId) are parsed
        resolutions.add(VideoResolution.fromJson(resJson));
      }

      // Sort highest quality first (backend already does this, but be safe)
      resolutions.sort((a, b) => b.height.compareTo(a.height));

      // ── Debug ──────────────────────────────────────────────────────────────
      debugPrint('=== EXTRACTOR DEBUG ===');
      debugPrint('Title: ${data['title']}');
      debugPrint('Raw resolutions from backend: ${rawResolutions.length}');
      debugPrint('Parsed resolutions: ${resolutions.length}');
      for (final r in resolutions) {
        debugPrint('  • ${r.label} (${r.height}p) muxed=${r.isMuxed} url=${r.videoStreamUrl != null ? "✅" : "❌NULL"}');
      }
      debugPrint('=======================');

      return VideoModel(
        id: (data['id'] as String?) ?? '',
        title: (data['title'] as String?) ?? 'Unknown Title',
        author: (data['author'] as String?) ?? 'Unknown',
        thumbnailUrl: (data['thumbnail'] as String?) ?? '',
        duration: Duration(
          seconds: (data['duration'] as num?)?.round() ?? 0,
        ),
        availableResolutions: resolutions,
      );
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'];
      throw Exception(detail ?? e.message ?? 'Network error');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  void dispose() => _dio.close();
}
