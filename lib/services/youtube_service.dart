import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_metadata.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<VideoMetadata?> fetchVideoMetadata(String url) async {
    try {
      final video = await _yt.videos.get(url);
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);

      // Get available resolutions
      final resolutions = <VideoResolution>[];

      // Muxed streams (usually up to 720p)
      for (final stream in manifest.muxed) {
        resolutions.add(VideoResolution(
          label: stream.videoQualityLabel,
          width: stream.videoResolution.width,
          height: stream.videoResolution.height,
          videoStreamUrl: stream.url.toString(),
          isMuxed: true,
        ));
      }

      // Adaptive streams (separate video and audio, for 1080p+)
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      for (final stream in manifest.videoOnly) {
        final label = stream.videoQualityLabel;
        // Only add if not already present in muxed (usually muxed is preferred for lower res)
        if (!resolutions.any((r) => r.label == label)) {
          resolutions.add(VideoResolution(
            label: label,
            width: stream.videoResolution.width,
            height: stream.videoResolution.height,
            videoStreamUrl: stream.url.toString(),
            audioStreamUrl: audioStream.url.toString(),
            isMuxed: false,
          ));
        }
      }

      // Sort resolutions by height descending
      resolutions.sort((a, b) => b.height.compareTo(a.height));

      return VideoMetadata(
        id: video.id.value,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
        availableResolutions: resolutions,
      );
    } catch (e) {
      print('Error fetching metadata: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
