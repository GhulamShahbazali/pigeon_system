import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationPrivacySettingsScreen extends StatefulWidget {
  const NotificationPrivacySettingsScreen({super.key});

  @override
  State<NotificationPrivacySettingsScreen> createState() => _NotificationPrivacySettingsScreenState();
}

class _NotificationPrivacySettingsScreenState extends State<NotificationPrivacySettingsScreen> {
  bool _allowPush = true;
  bool _newFollower = true;
  bool _likes = true;
  bool _tournamentUpdates = true;
  bool _liveRecords = false;
  bool _privateAccount = false;

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
        title: Text('Notifications & Privacy', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text('Push notifications', style: AppTextStyles.labelUppercase),
          ),
          _ToggleTile(
            title: 'Allow push',
            subtitle: 'Master switch',
            value: _allowPush,
            onChanged: (v) => setState(() => _allowPush = v),
          ),
          _ToggleTile(
            title: 'New follower',
            value: _newFollower,
            onChanged: (v) => setState(() => _newFollower = v),
          ),
          _ToggleTile(
            title: 'Likes on my content',
            value: _likes,
            onChanged: (v) => setState(() => _likes = v),
          ),
          _ToggleTile(
            title: 'Tournament I follow updates',
            value: _tournamentUpdates,
            onChanged: (v) => setState(() => _tournamentUpdates = v),
          ),
          _ToggleTile(
            title: 'Live record from people I follow',
            value: _liveRecords,
            onChanged: (v) => setState(() => _liveRecords = v),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('Privacy', style: AppTextStyles.labelUppercase),
          ),
          _ToggleTile(
            title: 'Private account',
            subtitle: 'Only approved followers can see your profile and records',
            icon: Icons.lock_outline_rounded,
            value: _privateAccount,
            onChanged: (v) => setState(() => _privateAccount = v),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hair)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.ok50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.ok, size: 18),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyBold),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
