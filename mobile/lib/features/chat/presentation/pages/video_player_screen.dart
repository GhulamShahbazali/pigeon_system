import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';

/// Minimal full-screen player for a chat video message.
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      await c.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not play this video.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white70))
            : !_ready || c == null
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(c),
                          VideoProgressIndicator(c, allowScrubbing: true,
                              colors: const VideoProgressColors(playedColor: AppColors.brand)),
                          if (!c.value.isPlaying)
                            const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
