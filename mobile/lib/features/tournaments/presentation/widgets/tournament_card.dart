import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_watermark.dart';

class TournamentCard extends StatelessWidget {
  final String title;
  final String organizer;
  final String days;
  final String schedule;
  final int pigeons;
  final int likes;
  final String views;
  final String? average;
  final bool isLive;
  final bool isCompleted;
  final String? liveLabel;
  final String? avatarUrl;
  final Gradient coverGradient;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.title,
    required this.organizer,
    required this.days,
    required this.schedule,
    required this.pigeons,
    required this.likes,
    required this.views,
    this.average,
    this.isLive = false,
    this.isCompleted = false,
    this.liveLabel,
    this.avatarUrl,
    this.coverGradient = AppColors.duskMesh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Container(
                height: 124,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                ),
                padding: const EdgeInsets.all(14),
                child: Stack(
                  children: [
                    // Watermark dove icon
                    const Positioned(
                      right: -14,
                      bottom: -24,
                      child: PigeonWatermark(
                        width: 140,
                        height: 140,
                        color: Color(0x24FFFFFF),
                      ),
                    ),

                    // Top Left Pill
                    if (isLive)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.white16,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.white28),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF51E39A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                liveLabel ?? 'LIVE',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Title & Organizer
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'by $organizer',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white90,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.sub),
                        const SizedBox(width: 5),
                        Text(days, style: AppTextStyles.caption.copyWith(color: AppColors.sub, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.circle, size: 3, color: AppColors.mut),
                        const SizedBox(width: 6),
                        Text(schedule, style: AppTextStyles.caption.copyWith(color: AppColors.sub, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.circle, size: 3, color: AppColors.mut),
                        const SizedBox(width: 6),
                        const Icon(Icons.emoji_events_outlined, size: 13, color: AppColors.amberInk),
                        const SizedBox(width: 4),
                        Text(
                          '$pigeons pigeons',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.amberInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.hair, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 16, color: AppColors.danger),
                        const SizedBox(width: 5),
                        Text('$likes', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.sub),
                        const SizedBox(width: 5),
                        Text(views, style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.sub)),
                        const Spacer(),
                        // Completed races show a green "done" check next to share.
                        if (isCompleted) ...[
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.ok),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.share_outlined, size: 17, color: AppColors.sub),
                        const SizedBox(width: 14),
                        AppAvatar(
                          text: organizer,
                          imageUrl: avatarUrl,
                          size: 26,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
