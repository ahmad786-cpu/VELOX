// lib/models/video_model.dart
//
// Single canonical model for the whole app.
// Do NOT create another VideoResolution anywhere — import from here.

class VideoModel {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final String? localPath;
  final List<VideoResolution> availableResolutions;

  const VideoModel({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    this.localPath,
    required this.availableResolutions,
  });

  String get url => 'https://www.youtube.com/watch?v=$id';

  VideoModel copyWith({String? localPath}) => VideoModel(
        id: id,
        title: title,
        author: author,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
        localPath: localPath ?? this.localPath,
        availableResolutions: availableResolutions,
      );
}

class VideoResolution {
  final String label;
  final int height;
  final String? formatId;

  /// Direct URL to the video stream.
  final String? videoStreamUrl;

  /// URL to the best separate audio stream (null when [isMuxed] == true).
  final String? audioStreamUrl;

  /// True  → single file contains both video + audio (≤ 720p on YouTube).
  /// False → video-only stream; must be merged with [audioStreamUrl] via FFmpeg.
  final bool isMuxed;

  /// Whether this stream is an HDR variant.
  final bool isHdr;

  /// Whether this stream is high frame-rate (≥ 60 fps).
  final bool isHfr;

  /// Container extension, e.g. "mp4", "webm".
  final String ext;

  const VideoResolution({
    required this.label,
    required this.height,
    this.formatId,
    this.videoStreamUrl,
    this.audioStreamUrl,
    this.isMuxed = false,
    this.isHdr = false,
    this.isHfr = false,
    this.ext = 'mp4',
  });

  factory VideoResolution.fromJson(Map<String, dynamic> json) {
    return VideoResolution(
      label: json['quality'] ?? '',
      height: json['height'] ?? 0,
      formatId: json['format_id'],
      videoStreamUrl: json['video_url'],
      audioStreamUrl: json['audio_url'],
      isMuxed: json['is_muxed'] ?? false,
      isHdr: json['is_hdr'] ?? false,
      isHfr: json['is_hfr'] ?? false,
      ext: json['ext'] ?? 'mp4',
    );
  }

  /// True when this stream needs FFmpeg to mux in a separate audio track.
  bool get needsFFmpeg => !isMuxed && audioStreamUrl != null;

  /// Human-readable quality tag shown in the quality picker.
  String get qualityTag {
    if (height >= 2160) return '4K';
    if (height >= 1440) return '2K';
    if (height >= 1080) return 'FHD';
    if (height >= 720)  return 'HD';
    if (height >= 480)  return 'SD';
    return 'LQ';
  }
}
