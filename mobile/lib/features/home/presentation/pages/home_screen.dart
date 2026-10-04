import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pigeon_logo.dart';
import '../../../home/presentation/widgets/live_now_strip.dart';
import '../../../tournaments/presentation/widgets/tournament_card.dart';
import '../../../tournaments/presentation/widgets/trending_tournament_row.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../../app/bloc/navigation_bloc.dart';
import '../../../../app/bloc/navigation_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
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
                      onTap: () {
                        // Switch to Tournaments tab (index 1) for search/browse
                        context.read<NavigationBloc>().add(const NavigationTabChangedEvent(1));
                      },
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
                          Text('① Live now', style: AppTextStyles.overline.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              // Switch to Records tab (index 2) where live records live
                              context.read<NavigationBloc>().add(const NavigationTabChangedEvent(2));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Text(
                                'See all',
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
                      onUserPressed: (name) => context.push('/records/live'),
                    ),
                    const Divider(color: AppColors.hair, height: 1),
                  ],
                ),
              ),
            ),

            // 3. Featured Tournament
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          Text('② Featured tournament', style: AppTextStyles.overline.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              // Switch to Tournaments tab (index 1)
                              context.read<NavigationBloc>().add(const NavigationTabChangedEvent(1));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Text(
                                'See all',
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
                    TournamentCard(
                      title: 'City Loft Championship',
                      organizer: 'Ahmed Loft',
                      days: '3 days',
                      schedule: 'Alternate',
                      pigeons: 20,
                      likes: 318,
                      views: '1.2k',
                      isLive: true,
                      liveLabel: 'LIVE · Day 2',
                      coverGradient: AppColors.duskMesh,
                      onTap: () => context.push('/tournaments/detail/city-loft'),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Trending Tournaments
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text('③ Trending tournaments', style: AppTextStyles.overline.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            context.read<NavigationBloc>().add(const NavigationTabChangedEvent(1));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Text(
                              'See all',
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
                  TrendingTournamentRow(
                    title: 'City Loft Championship',
                    detail: 'Day 2 · 20 pigeons',
                    average: '14:32',
                    isLive: true,
                    thumbGradient: AppColors.duskMesh,
                    onTap: () => context.push('/tournaments/detail/city-loft'),
                  ),
                  TrendingTournamentRow(
                    title: 'Spring Open Flyers',
                    detail: '1 day · 12 pigeons',
                    average: '11:08',
                    thumbGradient: AppColors.heroMeshSky,
                    onTap: () => context.push('/tournaments/detail/spring-open'),
                  ),
                  TrendingTournamentRow(
                    title: 'Valley Race Cup',
                    detail: '5 days · 30 pigeons',
                    average: '12:44',
                    thumbGradient: AppColors.dawnMesh,
                    onTap: () => context.push('/tournaments/detail/valley-cup'),
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
                    Text('④ From people you follow', style: AppTextStyles.overline.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push('/posts/create'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                          boxShadow: AppShadows.xs,
                        ),
                        child: Row(
                          children: [
                            const AppAvatar(text: 'Ahmed', size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Share something about your loft…',
                                style: AppTextStyles.subText.copyWith(color: AppColors.mut),
                              ),
                            ),
                            const Icon(Icons.image_outlined, color: AppColors.brand, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Posts Feed
            SliverToBoxAdapter(
              child: Column(
                children: [
                  PostCard(
                    authorName: 'Ahmed Loft',
                    timeAgo: '2h ago',
                    content: 'Morning kit flew beautifully today. 18 birds, all back by noon.',
                    mediaGradient: 'sky',
                    likes: 214,
                    shares: 12,
                    views: '1.3k',
                    isFollowing: true,
                    onFollowPressed: () {},
                    onLikePressed: () {},
                    onTap: () => context.push('/posts/detail'),
                    onAuthorTap: () => context.push('/user/ahmed?name=Ahmed+Loft&handle=@ahmed.loft&location=Lahore,+PK'),
                  ),
                  const Divider(color: AppColors.hair, height: 8, thickness: 8),
                  PostCard(
                    authorName: 'Kashif Pigeons',
                    timeAgo: '5h ago',
                    content: 'Who\'s joining the City Loft Championship this week?',
                    likes: 63,
                    shares: 4,
                    views: '540',
                    isFollowing: false,
                    onFollowPressed: () {},
                    onLikePressed: () {},
                    onTap: () => context.push('/posts/detail'),
                    onAuthorTap: () => context.push('/user/kashif?name=Kashif+Pigeons&handle=@kashif.pigeons&location=Faisalabad,+PK'),
                  ),
                  const Divider(color: AppColors.hair, height: 8, thickness: 8),
                  PostCard(
                    authorName: 'Sohail Khan',
                    timeAgo: '7h ago',
                    content: 'New young birds settling in well.',
                    likes: 88,
                    shares: 3,
                    views: '410',
                    isFollowing: true,
                    onFollowPressed: () {},
                    onLikePressed: () {},
                    onTap: () => context.push('/posts/detail'),
                    onAuthorTap: () => context.push('/user/sohail?name=Sohail+Khan&handle=@sohail.khan&location=Rawalpindi,+PK'),
                  ),
                ],
              ),
            ),

            // 7. Suggested to Follow (Wireframe Scroll 4)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Text('⑤ Suggested to follow', style: AppTextStyles.overline.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 6),
                    _buildSuggestedUserRow(
                      context,
                      name: 'Rashid Lofts',
                      info: 'Followed by Ahmed +3',
                      id: 'rashid',
                      location: 'Gujranwala, PK',
                    ),
                    _buildSuggestedUserRow(
                      context,
                      name: 'Naveed Pigeons',
                      info: 'Multan · 540 followers',
                      id: 'naveed',
                      location: 'Multan, PK',
                    ),
                  ],
                ),
              ),
            ),

            // 8. End of Feed Marker
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.ok, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re all caught up',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedUserRow(
    BuildContext context, {
    required String name,
    required String info,
    required String id,
    required String location,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.push('/user/$id?name=${Uri.encodeComponent(name)}&handle=@$id&location=${Uri.encodeComponent(location)}'),
            child: AppAvatar(text: name, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/user/$id?name=${Uri.encodeComponent(name)}&handle=@$id&location=${Uri.encodeComponent(location)}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(info, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Follow',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 20, color: AppColors.ink2),
            ),
            if (badge)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
