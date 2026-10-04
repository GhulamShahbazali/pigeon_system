import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  final bool isEmpty;

  const NotificationsScreen({super.key, this.isEmpty = false});

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
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
          title: Text('Notifications', style: AppTextStyles.h2),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.mut),
              ),
              const SizedBox(height: 16),
              Text('No notifications yet', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                'Follow tournaments and people to see live updates here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.mut),
              ),
            ],
          ),
        ),
      );
    }

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
        title: Text('Notifications', style: AppTextStyles.h2),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text('New', style: AppTextStyles.labelUppercase),
          ),
          _NotificationTile(
            icon: Icons.add_circle_outline_rounded,
            iconBg: AppColors.brand,
            titleSpan: [
              TextSpan(text: 'Ahmed Loft ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'created a new tournament — '),
              TextSpan(text: 'City Loft Championship', style: AppTextStyles.bodyBold),
              const TextSpan(text: '.'),
            ],
            time: 'just now',
            isUnread: true,
          ),
          _NotificationTile(
            icon: Icons.people_outline_rounded,
            iconBg: AppColors.purpleImage,
            titleSpan: [
              TextSpan(text: 'Bilal Raza ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'was added to '),
              TextSpan(text: 'City Loft Championship', style: AppTextStyles.bodyBold),
              const TextSpan(text: '.'),
            ],
            time: '3m ago',
            isUnread: true,
          ),
          _NotificationTile(
            icon: Icons.emoji_events_rounded,
            iconBg: AppColors.amber,
            titleSpan: [
              TextSpan(text: 'City Loft Championship ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'posted Day 2 results. Bilal Raza leads at 12:40.'),
            ],
            time: '8m ago',
            isUnread: true,
          ),
          _NotificationTile(
            icon: Icons.remove_red_eye_outlined,
            iconBg: AppColors.ok,
            titleSpan: [
              TextSpan(text: "Ahmed's loft ", style: AppTextStyles.bodyBold),
              const TextSpan(text: 'is flying live — 12 of 18 landed.'),
            ],
            time: '8m ago',
            isUnread: true,
          ),
          _NotificationTile(
            icon: Icons.favorite_rounded,
            iconBg: AppColors.danger,
            titleSpan: [
              TextSpan(text: '+42 people ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'liked a tournament you follow.'),
            ],
            time: '20m ago',
            isUnread: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('Earlier', style: AppTextStyles.labelUppercase),
          ),
          _NotificationTile(
            icon: Icons.person_add_alt_1_rounded,
            iconBg: AppColors.brand,
            titleSpan: [
              TextSpan(text: 'Kashif Ali ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'started following you.'),
            ],
            time: '1h ago',
            hasFollowButton: true,
          ),
          _NotificationTile(
            icon: Icons.favorite_rounded,
            iconBg: AppColors.danger,
            titleSpan: [
              TextSpan(text: 'Sohail Khan ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'liked your post.'),
            ],
            time: '3h ago',
          ),
          _NotificationTile(
            icon: Icons.emoji_events_rounded,
            iconBg: AppColors.amber,
            titleSpan: [
              TextSpan(text: 'Spring Open Flyers ', style: AppTextStyles.bodyBold),
              const TextSpan(text: 'has ended. Final average 11:08.'),
            ],
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final List<InlineSpan> titleSpan;
  final String time;
  final bool isUnread;
  final bool hasFollowButton;

  const _NotificationTile({
    required this.icon,
    required this.iconBg,
    required this.titleSpan,
    required this.time,
    this.isUnread = false,
    this.hasFollowButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.brand50.withValues(alpha: 0.35) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: AppColors.hair)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(color: AppColors.ink),
                    children: titleSpan,
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
              ],
            ),
          ),
          if (hasFollowButton) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Follow', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
