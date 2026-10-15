import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/bloc/navigation_bloc.dart';
import '../../../../app/bloc/navigation_event.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_logo.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../home/presentation/widgets/live_now_strip.dart';
import '../../../posts/data/posts_repository.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../tournaments/data/models/tournament_card_model.dart';
import '../../../tournaments/data/tournaments_repository.dart';
import '../../../tournaments/presentation/pages/tournament_detail_screen.dart';
import '../../../tournaments/presentation/widgets/tournament_card.dart';
import '../../../tournaments/presentation/widgets/trending_tournament_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TournamentsRepository _tournamentsRepo = sl<TournamentsRepository>();
  final PostsRepository _postsRepo = sl<PostsRepository>();
  final SocketService _socket = sl<SocketService>();

  List<TournamentCardModel> _tournaments = [];
  List<PostModel> _posts = [];
  final Set<String> _likedPostIds = {};
  final Map<String, int> _postLikeCounts = {};
  final Map<String, int> _postViewCounts = {};
  final Map<String, int> _postShareCounts = {};
  bool _isLoading = true;

  void _togglePostLike(String postId) {
    final liked = _likedPostIds.contains(postId);
    setState(() {
      if (liked) {
        _likedPostIds.remove(postId);
        _postLikeCounts[postId] = (_postLikeCounts[postId] ?? 1) - 1;
      } else {
        _likedPostIds.add(postId);
        _postLikeCounts[postId] = (_postLikeCounts[postId] ?? 0) + 1;
      }
    });
    if (liked) {
      _postsRepo.unlikePost(postId);
    } else {
      _postsRepo.likePost(postId);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _socket.off('post.new');
    _socket.off('post.counts');
    super.dispose();
  }

  /// Live updates: new posts arrive, and like/view/share counts change without refresh.
  void _setupRealtime() {
    _socket.subscribeFeed();
    _socket.onPostNew((_) {
      if (mounted) _loadDashboardData(); // a new post landed -> refresh feed
    });
    _socket.onPostCounts((data) {
      if (!mounted || data is! Map) return;
      final id = data['post_id']?.toString();
      if (id == null) return;
      setState(() {
        if (data['like_count'] != null) _postLikeCounts[id] = (data['like_count'] as num).toInt();
        if (data['view_count'] != null) _postViewCounts[id] = (data['view_count'] as num).toInt();
        if (data['share_count'] != null) _postShareCounts[id] = (data['share_count'] as num).toInt();
      });
    });
  }

  Future<void> _loadDashboardData() async {
    // Fire both requests together and await them in parallel — they are
    // independent, so there's no reason to pay two round-trips back-to-back.
    final tFuture = _tournamentsRepo.getTournaments(tab: 'all');
    final pFuture = _postsRepo.getFeed(tab: 'for_you', limit: 100);
    final tResult = await tFuture;
    final pResult = await pFuture;

    if (!mounted) return;

    setState(() {
      if (tResult.isSuccess) {
        _tournaments = (tResult as dynamic).data as List<TournamentCardModel>;
      }
      if (pResult.isSuccess) {
        _posts = (pResult as dynamic).data as List<PostModel>;
        _likedPostIds.clear();
        _postLikeCounts.clear();
        _postViewCounts.clear();
        _postShareCounts.clear();
        for (final p in _posts) {
          if (p.isLiked) _likedPostIds.add(p.id);
          _postLikeCounts[p.id] = p.likeCount;
          _postViewCounts[p.id] = p.viewCount;
          _postShareCounts[p.id] = p.shareCount;
          // Subscribe to this post's live count room.
          _socket.subscribePostCounts(p.id);
        }
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            slivers: [
              // 1. Top Brand Header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const PigeonLogo(size: 34),
                      const SizedBox(width: 10),
                      Text(
                        'PigeonFly',
                        style: AppTextStyles.screenTitle.copyWith(fontSize: 21),
                      ),
                      const Spacer(),
                      _buildIconButton(
                        icon: Icons.search_rounded,
                        onTap: () => context.push('/discovery/find-friends'),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        badge: true,
                        onTap: () => context.push('/messages'),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.notifications_none_rounded,
                        badge: true,
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Live Now Section
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            Text('① ${s.liveNow}',
                                style: AppTextStyles.overline.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8)),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                context
                                    .read<NavigationBloc>()
                                    .add(const NavigationTabChangedEvent(2));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 4),
                                child: Text(
                                  s.seeAll,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LiveNowStrip(
                        onGoLivePressed: () => context.push('/records/create'),
                        onUserPressed: (recordId) => context.push('/records/live/$recordId'),
                      ),
                      const Divider(color: AppColors.hair, height: 1),
                    ],
                  ),
                ),
              ),

              // 3. Featured Tournament
              if (_tournaments.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Text('② ${s.featuredTournament}',
                            style: AppTextStyles.overline.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8)),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            context
                                .read<NavigationBloc>()
                                .add(const NavigationTabChangedEvent(1));
                          },
                          child: Text(
                            s.exploreAll,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TournamentCard(
                    title: _tournaments.first.title,
                    organizer:
                        _tournaments.first.organizer?.displayName ?? 'Organizer',
                    days: _tournaments.first.daysDisplay,
                    schedule: _tournaments.first.scheduleDisplay,
                    pigeons: _tournaments.first.pigeonCount,
                    likes: _tournaments.first.likeCount,
                    views: _tournaments.first.viewCount.toString(),
                    isLive: _tournaments.first.isLive,
                    coverGradient: AppColors.duskMesh,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => TournamentDetailScreen(
                            tournamentId: _tournaments.first.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 4. Trending Tournaments
              if (_tournaments.length > 1)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Text('③ ${s.trendingTournaments}',
                                style: AppTextStyles.overline.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8)),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                context
                                    .read<NavigationBloc>()
                                    .add(const NavigationTabChangedEvent(1));
                              },
                              child: Text(
                                s.seeAll,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._tournaments.skip(1).take(3).map(
                            (t) => TrendingTournamentRow(
                              title: t.title,
                              detail: '${t.daysDisplay} · ${t.pigeonCount} pigeons',
                              average: 'Live Standings',
                              isLive: t.isLive,
                              thumbGradient: AppColors.heroMeshSky,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => TournamentDetailScreen(
                                      tournamentId: t.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ),

              // 5. Compose Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('④ ${s.feedCommunity}',
                          style: AppTextStyles.overline.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          await context.push('/posts/create');
                          _loadDashboardData();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                            boxShadow: AppShadows.xs,
                          ),
                          child: Row(
                            children: [
                              const AppAvatar(name: 'Me', size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.shareLoftHint,
                                  style: AppTextStyles.subText
                                      .copyWith(color: AppColors.mut),
                                ),
                              ),
                              const Icon(Icons.image_outlined,
                                  color: AppColors.brand, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Posts Feed
              if (_isLoading && _posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.brand),
                    ),
                  ),
                )
              else if (_posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.feed_outlined,
                              color: AppColors.muted, size: 40),
                          const SizedBox(height: 8),
                          Text(s.noPostsInFeed,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _posts[index];
                      return Column(
                        children: [
                          PostCard(
                            authorName: post.author.displayName,
                            avatarUrl: post.author.photoUrl,
                            timeAgo: 'Recently',
                            content: post.content,
                            imageUrl: post.imageUrl,
                            likes: _postLikeCounts[post.id] ?? post.likeCount,
                            shares: _postShareCounts[post.id] ?? post.shareCount,
                            views: (_postViewCounts[post.id] ?? post.viewCount).toString(),
                            isLiked: _likedPostIds.contains(post.id),
                            onFollowPressed: () {},
                            onLikePressed: () => _togglePostLike(post.id),
                            onTap: () => context.push('/posts/detail', extra: post),
                            onAuthorTap: () => context.push(
                              '/user/${post.author.id}',
                              extra: post.author,
                            ),
                          ),
                          const Divider(
                              color: AppColors.hair, height: 8, thickness: 8),
                        ],
                      );
                    },
                    childCount: _posts.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            if (badge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
