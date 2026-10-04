import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: Text('Settings', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text('Account', style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.edit_outlined,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: 'Edit profile',
            onTap: () => context.push('/settings/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconBg: AppColors.amber50,
            iconColor: AppColors.amberInk,
            title: 'Language',
            trailing: Text('English', style: AppTextStyles.body.copyWith(color: AppColors.sub)),
            onTap: () => context.push('/settings/language'),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('Preferences', style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            iconBg: AppColors.brand50,
            iconColor: AppColors.brand,
            title: 'Notifications',
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconBg: AppColors.ok50,
            iconColor: AppColors.ok,
            title: 'Privacy',
            onTap: () => context.push('/settings/notifications'),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('Support', style: AppTextStyles.labelUppercase),
          ),
          _SettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: 'Contact us',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconBg: AppColors.soft,
            iconColor: AppColors.ink2,
            title: 'About PigeonFly',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconBg: AppColors.danger50,
            iconColor: AppColors.danger,
            title: 'Log out',
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
