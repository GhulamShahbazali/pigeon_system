import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String name;
  final String handle;
  final String location;

  const OtherUserProfileScreen({
    super.key,
    this.name = 'Kashif Ali',
    this.handle = '@kashif.pigeons',
    this.location = 'Faisalabad, PK',
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover with avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.duskMesh),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                                onPressed: () {},
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
                      text: 'K',
                      size: 80,
                      gradient: AppColors.avatarPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // User Info
            Text(widget.name, style: AppTextStyles.h2),
            const SizedBox(height: 2),
            Text('${widget.handle} · ${widget.location}', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
            const SizedBox(height: 16),

            // Follow & Chat buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: _isFollowing ? 'Following' : 'Follow',
                      icon: _isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                      variant: _isFollowing ? AppButtonVariant.soft : AppButtonVariant.primary,
                      onPressed: () => setState(() => _isFollowing = !_isFollowing),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            contactName: widget.name,
                            isOnline: false,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadows.xs,
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.ink2, size: 20),
                    ),
                  ),
                ],
              ),
            ),
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
                  _StatItem(number: '8', label: 'Tournaments'),
                  _StatItem(number: '920', label: 'Followers'),
                  _StatItem(number: '210', label: 'Following'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Rows
            _ContentRow(icon: Icons.emoji_events_outlined, title: 'Tournaments', count: 8),
            _ContentRow(icon: Icons.dynamic_feed_rounded, title: 'Posts', count: 24),
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

class _ContentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _ContentRow({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.ink2, size: 18),
          ),
          const SizedBox(width: 14),
          Text(title, style: AppTextStyles.bodyBold),
          const Spacer(),
          Text('$count', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mut),
        ],
      ),
    );
  }
}
