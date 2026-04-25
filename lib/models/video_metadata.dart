class VideoMetadata {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final List<VideoResolution> availableResolutions;

  VideoMetadata({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.availableResolutions,
  });

  String get url => 'https://www.youtube.com/watch?v=$id';
}

class VideoResolution {
  final String label; // e.g., "1080p", "720p"
  final int width;
  final int height;
  final String? videoStreamUrl;
  final String? audioStreamUrl;
  final bool isMuxed; // True if it contains both audio and video

  VideoResolution({
    required this.label,
    required this.width,
    required this.height,
    this.videoStreamUrl,
    this.audioStreamUrl,
    this.isMuxed = false,
  });
}
