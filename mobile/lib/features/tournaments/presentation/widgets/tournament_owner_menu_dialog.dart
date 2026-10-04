import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class TournamentOwnerMenuDialog extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onManageParticipants;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const TournamentOwnerMenuDialog({
    super.key,
    this.onEdit,
    this.onManageParticipants,
    this.onShare,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onEdit,
    VoidCallback? onManageParticipants,
    VoidCallback? onShare,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournamentOwnerMenuDialog(
        onEdit: onEdit,
        onManageParticipants: onManageParticipants,
        onShare: onShare,
        onDelete: onDelete,
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
          _MenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit tournament',
            onTap: () {
              Navigator.of(context).pop();
              onEdit?.call();
            },
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.people_outline_rounded,
            title: 'Manage participants',
            onTap: () {
              Navigator.of(context).pop();
              onManageParticipants?.call();
            },
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.share_outlined,
            title: 'Share',
            onTap: () {
              Navigator.of(context).pop();
              onShare?.call();
            },
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete tournament',
            isDanger: true,
            onTap: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDanger;
  final VoidCallback onTap;

  const _MenuTile({
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
