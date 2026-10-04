import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class TournamentShareDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? shareUrl;
  final bool isParticipant;

  const TournamentShareDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.shareUrl,
    this.isParticipant = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? shareUrl,
    bool isParticipant = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournamentShareDialog(
        title: title,
        subtitle: subtitle,
        shareUrl: shareUrl,
        isParticipant: isParticipant,
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
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
          const SizedBox(height: 16),
          if (shareUrl != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.soft,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppColors.brand, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      shareUrl!,
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('Copy', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (isParticipant) ...[
            _ShareOptionTile(
              icon: Icons.table_chart_rounded,
              iconBg: AppColors.greenExcel,
              title: 'Excel spreadsheet',
              badge: '.xlsx',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            _ShareOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              iconBg: AppColors.danger,
              title: 'PDF report',
              badge: '.pdf',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            _ShareOptionTile(
              icon: Icons.description_rounded,
              iconBg: AppColors.brand,
              title: 'Text summary',
              badge: 'copy / send',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            _ShareOptionTile(
              icon: Icons.image_rounded,
              iconBg: AppColors.purpleImage,
              title: 'Image card',
              badge: '.png',
              onTap: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            _ShareOptionTile(
              icon: Icons.share_rounded,
              iconBg: AppColors.brand,
              title: 'Share link',
              badge: 'WhatsApp · anywhere',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            _ShareOptionTile(
              icon: Icons.table_chart_rounded,
              iconBg: AppColors.greenExcel,
              title: 'Export standings',
              badge: '.xlsx',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            _ShareOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              iconBg: AppColors.danger,
              title: 'PDF report',
              badge: '.pdf',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String badge;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.badge,
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
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Text(title, style: AppTextStyles.bodyBold),
            const Spacer(),
            Text(badge, style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
