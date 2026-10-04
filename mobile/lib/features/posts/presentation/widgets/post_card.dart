import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_watermark.dart';

class PostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String content;
  final String? mediaGradient;
  final int likes;
  final int shares;
  final String views;
  final bool isFollowing;
  final VoidCallback onFollowPressed;
  final VoidCallback onLikePressed;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;

  const PostCard({
    super.key,
    required this.authorName,
    required this.timeAgo,
    required this.content,
    this.mediaGradient,
    required this.likes,
    required this.shares,
    required this.views,
    this.isFollowing = false,
    required this.onFollowPressed,
    required this.onLikePressed,
    this.onTap,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.card,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: onAuthorTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppAvatar(text: authorName, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: AppTextStyles.bodyBold,
                            ),
                            Text(
                              '$timeAgo · Public',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                InkWell(
                  onTap: onFollowPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.transparent : AppColors.brand,
                      borderRadius: BorderRadius.circular(12),
                      border: isFollowing ? Border.all(color: AppColors.line) : null,
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isFollowing ? AppColors.ink : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Caption Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              content,
              style: AppTextStyles.bodyRegular.copyWith(height: 1.4),
            ),
          ),

          // Media block (if any)
          if (mediaGradient != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 210,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroMeshSky,
              ),
              child: const Center(
                child: PigeonWatermark(
                  width: 108,
                  height: 108,
                  color: Color(0xE6FFFFFF),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                InkWell(
                  onTap: onLikePressed,
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 18, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text('$likes', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Row(
                  children: [
                    const Icon(Icons.share_outlined, size: 18, color: AppColors.sub),
                    const SizedBox(width: 6),
                    Text('$shares', style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.sub)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.mut),
                    const SizedBox(width: 6),
                    Text(views, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
