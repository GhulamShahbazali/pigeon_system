import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../records/data/records_repository.dart';

class LiveNowStrip extends StatefulWidget {
  final VoidCallback onGoLivePressed;
  final ValueChanged<String> onUserPressed;

  const LiveNowStrip({
    super.key,
    required this.onGoLivePressed,
    required this.onUserPressed,
  });

  @override
  State<LiveNowStrip> createState() => _LiveNowStripState();
}

class _LiveNowStripState extends State<LiveNowStrip> {
  final RecordsRepository _recordsRepository = sl<RecordsRepository>();
  List<LiveRecordPreviewModel> _liveRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    final result = await _recordsRepository.getLiveNow();
    if (!mounted) return;
    result.when(
      success: (data) {
        setState(() {
          _liveRecords = data;
          _isLoading = false;
        });
      },
      failure: (_, __) {
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 94,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
          ),
        ),
      );
    }

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _liveRecords.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Go live" button
            return InkWell(
              onTap: widget.onGoLivePressed,
              borderRadius: BorderRadius.circular(30),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.brand100,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      color: AppColors.soft,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.brand,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Go live',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final record = _liveRecords[index - 1];
          final name = record.owner?.displayName ?? 'Flyer';

          return InkWell(
            onTap: () => widget.onUserPressed(record.id),
            borderRadius: BorderRadius.circular(30),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.ok,
                        Color(0xFF51E39A),
                        AppColors.ok,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: AppAvatar(
                      name: name,
                      imageUrl: record.owner?.photoUrl,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 62,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
