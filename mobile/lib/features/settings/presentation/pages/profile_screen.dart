import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_watermark.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Cover & Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.heroMeshSky),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: -20,
                        bottom: -30,
                        child: PigeonWatermark(
                          width: 150,
                          height: 150,
                          color: Color(0x29FFFFFF),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                                onPressed: () => context.push('/settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const AppAvatar(
                      text: 'A',
                      size: 80,
                      gradient: AppColors.avatarBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // User Info
            Text('Ahmed Raza', style: AppTextStyles.h2),
            const SizedBox(height: 2),
            Text('@ahmed_loft · Lahore, PK', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
            const SizedBox(height: 16),

            // Stats row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: AppShadows.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(number: '12', label: 'Tournaments'),
                  _StatItem(number: '1.4k', label: 'Followers'),
                  _StatItem(number: '340', label: 'Following'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Rows: My Tournaments, My Posts, My Records
            _ProfileLinkRow(
              icon: Icons.emoji_events_outlined,
              title: 'My Tournaments',
              count: 12,
              onTap: () {},
            ),
            _ProfileLinkRow(
              icon: Icons.dynamic_feed_rounded,
              title: 'My Posts',
              count: 38,
              onTap: () {},
            ),
            _ProfileLinkRow(
              icon: Icons.format_list_bulleted_rounded,
              title: 'My Records',
              count: 26,
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(number, style: AppTextStyles.h3),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
      ],
    );
  }
}

class _ProfileLinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _ProfileLinkRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.ink2, size: 18),
        ),
        title: Text(title, style: AppTextStyles.bodyBold),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mut),
          ],
        ),
      ),
    );
  }
}
