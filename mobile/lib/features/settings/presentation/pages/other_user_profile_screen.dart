import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../posts/presentation/pages/my_posts_screen.dart';
import '../../../tournaments/presentation/pages/user_tournaments_list_screen.dart';
import '../../data/user_repository.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialPhotoUrl;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialPhotoUrl,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final UserRepository _repo = sl<UserRepository>();
  UserProfileModel? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.getUserProfile(widget.userId);
    if (!mounted) return;
    res.when(
      success: (p) => setState(() {
        _profile = p;
        _isFollowing = p.isFollowing;
        _loading = false;
      }),
      failure: (_, __) => setState(() => _loading = false),
    );
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final was = _isFollowing;
    setState(() {
      _isFollowing = !was;
      _followBusy = true;
    });
    final r = was ? await _repo.unfollow(widget.userId) : await _repo.follow(widget.userId);
    if (!mounted) return;
    setState(() {
      if (r.isFailure) _isFollowing = was; // revert on failure
      _followBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.displayName ?? widget.initialName ?? 'Flyer';
    final username = _profile?.username;
    final photo = _profile?.photoUrl ?? widget.initialPhotoUrl;
    final location = _profile?.city ?? '';
    final handle = username != null ? '@$username' : '';

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
                        child: PigeonWatermark(width: 150, height: 150, color: Color(0x29FFFFFF)),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
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
                    child: AppAvatar(text: name, imageUrl: photo, size: 80, gradient: AppColors.avatarPurple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            Text(name, style: AppTextStyles.h2),
            const SizedBox(height: 2),
            Text([handle, location].where((s) => s.isNotEmpty).join(' · '),
                style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
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
                      onPressed: _toggleFollow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => ChatScreen(
                          contactName: name,
                          otherUserId: widget.userId,
                          contactPhotoUrl: photo,
                        ),
                      ));
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

            if (_loading && _profile == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
              )
            else ...[
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
                    _StatItem(number: '${_profile?.tournamentCount ?? 0}', label: 'Tournaments'),
                    _StatItem(number: '${_profile?.followerCount ?? 0}', label: 'Followers'),
                    _StatItem(number: '${_profile?.followingCount ?? 0}', label: 'Following'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _ContentRow(
                icon: Icons.emoji_events_outlined,
                title: 'Tournaments',
                count: _profile?.tournamentCount ?? 0,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UserTournamentsListScreen(userId: widget.userId, title: '$name • Tournaments'),
                )),
              ),
              _ContentRow(
                icon: Icons.dynamic_feed_rounded,
                title: 'Posts',
                count: _profile?.postCount ?? 0,
                showCount: _profile?.postCount != null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MyPostsScreen(userId: widget.userId, title: '$name • Posts'),
                )),
              ),
            ],
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
  final bool showCount;
  final VoidCallback onTap;

  const _ContentRow({
    required this.icon,
    required this.title,
    required this.count,
    this.showCount = true,
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
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.ink2, size: 18),
        ),
        title: Text(title, style: AppTextStyles.bodyBold),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCount) Text('$count', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mut),
          ],
        ),
      ),
    );
  }
}
