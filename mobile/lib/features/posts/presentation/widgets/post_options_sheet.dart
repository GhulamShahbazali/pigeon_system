import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class PostOptionsSheet extends StatelessWidget {
  final String authorName;
  final VoidCallback? onHide;
  final VoidCallback? onUnfollow;
  final VoidCallback? onCopyLink;
  final VoidCallback? onReport;

  const PostOptionsSheet({
    super.key,
    this.authorName = 'Ahmed Loft',
    this.onHide,
    this.onUnfollow,
    this.onCopyLink,
    this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    String authorName = 'Ahmed Loft',
    VoidCallback? onHide,
    VoidCallback? onUnfollow,
    VoidCallback? onCopyLink,
    VoidCallback? onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostOptionsSheet(
        authorName: authorName,
        onHide: onHide,
        onUnfollow: onUnfollow,
        onCopyLink: onCopyLink,
        onReport: onReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          _OptionItem(
            icon: Icons.visibility_off_outlined,
            title: 'Hide this post',
            onTap: () {
              Navigator.of(context).pop();
              onHide?.call();
            },
          ),
          const SizedBox(height: 10),
          _OptionItem(
            icon: Icons.block_flipped,
            title: 'Unfollow $authorName',
            onTap: () {
              Navigator.of(context).pop();
              onUnfollow?.call();
            },
          ),
          const SizedBox(height: 10),
          _OptionItem(
            icon: Icons.link_rounded,
            title: 'Copy link',
            onTap: () {
              Navigator.of(context).pop();
              onCopyLink?.call();
            },
          ),
          const SizedBox(height: 10),
          _OptionItem(
            icon: Icons.flag_outlined,
            title: 'Report post',
            isDanger: true,
            onTap: () {
              Navigator.of(context).pop();
              onReport?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDanger;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.title,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDanger ? AppColors.danger50 : AppColors.soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isDanger ? AppColors.danger : AppColors.ink2, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(
                color: isDanger ? AppColors.danger : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
