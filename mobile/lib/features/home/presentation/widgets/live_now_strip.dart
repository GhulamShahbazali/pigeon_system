import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

class LiveNowStrip extends StatelessWidget {
  final VoidCallback onGoLivePressed;
  final ValueChanged<String> onUserPressed;

  const LiveNowStrip({
    super.key,
    required this.onGoLivePressed,
    required this.onUserPressed,
  });

  @override
  Widget build(BuildContext context) {
    final liveUsers = [
      {'name': 'Ahmed', 'gradient': AppColors.avatarBlue},
      {'name': 'Kashif', 'gradient': AppColors.avatarPurple},
      {'name': 'Usman', 'gradient': AppColors.avatarGold},
      {'name': 'Sara', 'gradient': AppColors.avatarGreen},
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: liveUsers.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Go live" button
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

          final user = liveUsers[index - 1];
          return InkWell(
            onTap: () => onUserPressed(user['name'] as String),
            borderRadius: BorderRadius.circular(30),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.ok,
                        const Color(0xFF51E39A),
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
                      text: user['name'] as String,
                      size: 46,
                      gradient: user['gradient'] as Gradient,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user['name'] as String,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w600,
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
