import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class TrendingTournamentRow extends StatelessWidget {
  final String title;
  final String detail;
  final String average;
  final bool isLive;
  final Gradient thumbGradient;
  final VoidCallback onTap;

  const TrendingTournamentRow({
    super.key,
    required this.title,
    required this.detail,
    required this.average,
    this.isLive = false,
    this.thumbGradient = AppColors.heroMeshSky,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: thumbGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 26,
                      color: AppColors.white90,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyBold,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (isLive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ok50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.ok,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ok,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Average Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      average,
                      style: AppTextStyles.statNumber,
                    ),
                    Text(
                      'AVG',
                      style: AppTextStyles.overline.copyWith(
                        fontSize: 9,
                        color: AppColors.mut,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
