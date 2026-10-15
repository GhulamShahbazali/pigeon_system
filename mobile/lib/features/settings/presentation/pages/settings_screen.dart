import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(s.settings, style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(s.account, style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.edit_outlined,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: s.editProfile,
            onTap: () => context.push('/settings/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconBg: AppColors.amber50,
            iconColor: AppColors.amberInk,
            title: s.language,
            trailing: Text(s.lang.name, style: AppTextStyles.body.copyWith(color: AppColors.sub)),
            onTap: () => context.push('/settings/language'),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(s.preferences, style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            iconBg: AppColors.brand50,
            iconColor: AppColors.brand,
            title: s.notifications,
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconBg: AppColors.ok50,
            iconColor: AppColors.ok,
            title: s.privacy,
            onTap: () => context.push('/settings/notifications'),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(s.support, style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: s.contactUs,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: s.aboutApp,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconBg: AppColors.danger50,
            iconColor: AppColors.danger,
            title: s.logOut,
            isDanger: true,
            hasChevron: false,
            onTap: () {
              context.go('/auth/sign-in');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final bool isDanger;
  final bool hasChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.isDanger = false,
    this.hasChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hair)),
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
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(
                color: isDanger ? AppColors.danger : AppColors.ink,
              ),
            ),
            const Spacer(),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 6),
            ],
            if (hasChevron)
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mut),
          ],
        ),
      ),
    );
  }
}
