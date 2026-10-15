import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../../../../app/bloc/navigation_bloc.dart';
import '../../../../app/bloc/navigation_state.dart';
import '../../../records/data/records_repository.dart';
import '../../../records/presentation/pages/my_records_screen.dart';
import '../../../posts/data/posts_repository.dart';
import '../../../posts/presentation/pages/my_posts_screen.dart';
import '../../../tournaments/data/tournaments_repository.dart';
import '../../data/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _profileTabIndex = 3;

  final UserRepository _userRepo = sl<UserRepository>();
  final TournamentsRepository _tournamentsRepo = sl<TournamentsRepository>();
  final RecordsRepository _recordsRepo = sl<RecordsRepository>();
  final PostsRepository _postsRepo = sl<PostsRepository>();
  final SocketService _socket = sl<SocketService>();

  UserProfileModel? _profile;
  bool _isLoading = true;
  bool _refreshing = false;
  int _myTournamentsCount = 0;
  int _myRecordsCount = 0;
  int _myPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Live refresh: a follow (and other user-room events) arrive on the already
    // connected socket; re-pull the stats so Followers/Following update in real
    // time while this screen is visible. (Silent → no full-screen spinner.)
    _socket.onNotification(_onRealtimeEvent);
  }

  @override
  void dispose() {
    _socket.off('notification.new');
    super.dispose();
  }

  void _onRealtimeEvent(dynamic _) {
    if (mounted) _loadProfile(silent: true);
  }

  /// [silent] = refresh counts in place without the full-screen loader (used for
  /// live socket updates and tab re-focus); the first load is non-silent.
  Future<void> _loadProfile({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      final pResult = await _userRepo.getMyProfile();
      final tResult = await _tournamentsRepo.getTournaments(tab: 'mine');
      final rResult = await _recordsRepo.getMyRecords();
      if (pResult.isSuccess) {
        _profile = (pResult as dynamic).data as UserProfileModel;
        final postsResult = await _postsRepo.getUserPosts(_profile!.id);
        if (postsResult.isSuccess) {
          _myPostsCount = ((postsResult as dynamic).data as List).length;
        }
      }

      if (!mounted) return;

      setState(() {
        if (tResult.isSuccess) {
          _myTournamentsCount = ((tResult as dynamic).data as List).length;
        }
        if (rResult.isSuccess) {
          _myRecordsCount = ((rResult as dynamic).data as List).length;
        }
        if (!silent) _isLoading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.displayName ?? 'Flyer';
    final handle = '@${_profile?.username ?? 'flyer'}';
    final location = _profile?.city ?? 'Lahore, PK';
    final photoUrl = _profile?.photoUrl;
    final followers = _profile?.followerCount ?? 0;
    final following = _profile?.followingCount ?? 0;
    final tournaments = _profile?.tournamentCount != 0 ? (_profile?.tournamentCount ?? _myTournamentsCount) : _myTournamentsCount;

    return BlocListener<NavigationBloc, NavigationState>(
      // Re-pull stats each time the Profile tab is focused. IndexedStack keeps this
      // screen alive, so initState alone never refreshes on a tab switch.
      listenWhen: (prev, curr) =>
          curr.selectedIndex == _profileTabIndex && prev.selectedIndex != _profileTabIndex,
      listener: (_, __) => _loadProfile(silent: true),
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                                  onPressed: () async {
                                    await context.push('/settings');
                                    _loadProfile();
                                  },
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
                      child: AppAvatar(
                        text: name,
                        imageUrl: photoUrl,
                        size: 80,
                        gradient: AppColors.avatarBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // User Info
              if (_isLoading && _profile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                    ),
                  ),
                )
              else ...[
                Text(name, style: AppTextStyles.h2),
                const SizedBox(height: 2),
                Text('$handle · $location', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
              ],
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
                    InkWell(
                      onTap: () async {
                        await context.push('/profile/tournaments');
                        _loadProfile();
                      },
                      child: _StatItem(number: '$tournaments', label: 'Tournaments'),
                    ),
                    _StatItem(number: '$followers', label: 'Followers'),
                    _StatItem(number: '$following', label: 'Following'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content Rows: My Tournaments, My Posts, My Records
              _ProfileLinkRow(
                icon: Icons.emoji_events_outlined,
                title: 'My Tournaments',
                count: _myTournamentsCount,
                onTap: () async {
                  await context.push('/profile/tournaments');
                  _loadProfile();
                },
              ),
              _ProfileLinkRow(
                icon: Icons.dynamic_feed_rounded,
                title: 'My Posts',
                count: _myPostsCount,
                onTap: () {
                  final id = _profile?.id;
                  if (id == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MyPostsScreen(userId: id, title: 'My Posts'),
                  ));
                },
              ),
              _ProfileLinkRow(
                icon: Icons.format_list_bulleted_rounded,
                title: 'My Records',
                count: _myRecordsCount,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MyRecordsScreen(),
                  ));
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
