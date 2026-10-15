import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A playable voice-note bubble. Owns its own [AudioPlayer] so each note plays
/// independently; streams position so the progress bar + time update live.
class VoiceBubble extends StatefulWidget {
  final String url;
  final int? durationSeconds;
  final bool isMe;

  const VoiceBubble({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (!_loaded) {
        setState(() => _loading = true);
        await _player.setUrl(widget.url);
        _loaded = true;
        if (mounted) setState(() => _loading = false);
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isMe ? Colors.white : AppColors.brand;
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggle,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isMe ? AppColors.white28 : AppColors.brand50,
                  shape: BoxShape.circle,
                ),
                child: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                      )
                    : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: accent, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, posSnap) {
                final total = _player.duration ??
                    Duration(seconds: widget.durationSeconds ?? 0);
                final pos = posSnap.data ?? Duration.zero;
                final frac = total.inMilliseconds == 0
                    ? 0.0
                    : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 96,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 4,
                          backgroundColor: widget.isMe ? AppColors.white28 : AppColors.line,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playing || pos > Duration.zero
                          ? _fmt(pos)
                          : (total > Duration.zero ? _fmt(total) : '0:00'),
                      style: AppTextStyles.captionBold.copyWith(
                        color: widget.isMe ? AppColors.white90 : AppColors.mut,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
