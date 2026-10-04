import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatOptionsSheet extends StatelessWidget {
  final String contactName;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMedia;
  final VoidCallback? onMute;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;

  const ChatOptionsSheet({
    super.key,
    this.contactName = 'Ahmed Loft',
    this.onViewProfile,
    this.onMedia,
    this.onMute,
    this.onBlock,
    this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    String contactName = 'Ahmed Loft',
    VoidCallback? onViewProfile,
    VoidCallback? onMedia,
    VoidCallback? onMute,
    VoidCallback? onBlock,
    VoidCallback? onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatOptionsSheet(
        contactName: contactName,
        onViewProfile: onViewProfile,
        onMedia: onMedia,
        onMute: onMute,
        onBlock: onBlock,
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
          _ChatOptionTile(
            icon: Icons.person_outline_rounded,
            title: 'View profile',
            onTap: () {
              Navigator.of(context).pop();
              onViewProfile?.call();
            },
          ),
          const SizedBox(height: 10),
          _ChatOptionTile(
            icon: Icons.folder_outlined,
            title: 'Media, links & files',
            onTap: () {
              Navigator.of(context).pop();
              onMedia?.call();
            },
          ),
          const SizedBox(height: 10),
          _ChatOptionTile(
            icon: Icons.notifications_off_outlined,
            title: 'Mute notifications',
            onTap: () {
              Navigator.of(context).pop();
              onMute?.call();
            },
          ),
          const SizedBox(height: 10),
          _ChatOptionTile(
            icon: Icons.block_flipped,
            title: 'Block $contactName',
            isDanger: true,
            onTap: () {
              Navigator.of(context).pop();
              onBlock?.call();
            },
          ),
          const SizedBox(height: 10),
          _ChatOptionTile(
            icon: Icons.flag_outlined,
            title: 'Report',
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

class _ChatOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDanger;
  final VoidCallback onTap;

  const _ChatOptionTile({
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
