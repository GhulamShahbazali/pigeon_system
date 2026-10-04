import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class TournamentContactDialog extends StatelessWidget {
  final String organizerName;
  final String phoneNumber;

  const TournamentContactDialog({
    super.key,
    this.organizerName = 'Ahmed Loft',
    this.phoneNumber = '+92 300 1234567',
  });

  static Future<void> show(BuildContext context, {String organizerName = 'Ahmed Loft', String phoneNumber = '+92 300 1234567'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournamentContactDialog(organizerName: organizerName, phoneNumber: phoneNumber),
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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brand,
            child: Text(
              organizerName.isNotEmpty ? organizerName[0] : 'A',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(organizerName, style: AppTextStyles.h4),
              Text(' · Organizer', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(phoneNumber, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: AppColors.whatsApp,
            title: 'WhatsApp',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.business_center_rounded,
            iconBg: AppColors.whatsAppBusiness,
            title: 'WhatsApp Business',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.phone_rounded,
            iconBg: AppColors.brand,
            title: 'Call',
            trailing: 'Dial pad',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.copy_rounded,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: 'Copy number',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconBg,
    this.iconColor = Colors.white,
    required this.title,
    this.trailing,
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
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Text(title, style: AppTextStyles.bodyBold),
            if (trailing != null) ...[
              const Spacer(),
              Text(trailing!, style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
