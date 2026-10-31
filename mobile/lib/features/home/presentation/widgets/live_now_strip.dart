import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../records/data/records_repository.dart';

/// Horizontal "Live now" strip on Home. Data is owned by HomeScreen and passed
/// in, so it refreshes whenever Home refreshes (tab focus / pull-to-refresh)
/// instead of only once at startup.
class LiveNowStrip extends StatelessWidget {
  final List<LiveRecordPreviewModel> records;
  final bool isLoading;
  final VoidCallback onGoLivePressed;
  final ValueChanged<String> onUserPressed;

  const LiveNowStrip({
    super.key,
    this.records = const [],
    this.isLoading = false,
    required this.onGoLivePressed,
    required this.onUserPressed,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (isLoading && records.isEmpty) {
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
        itemCount: records.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return InkWell(
              onTap: onGoLivePressed,
              borderRadius: BorderRadius.circular(30),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brand100, width: 2),
                      color: AppColors.soft,
                    ),
                    child: const Center(
                      child: Icon(Icons.add_rounded, color: AppColors.brand, size: 26),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.goLive,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final record = records[index - 1];
          final name = record.owner?.displayName ?? s.flyer;

          return InkWell(
            onTap: () => onUserPressed(record.id),
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
                      colors: [AppColors.ok, Color(0xFF51E39A), AppColors.ok],
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
