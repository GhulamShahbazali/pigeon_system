import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/tournament_card.dart';
import 'tournament_detail_screen.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  int _selectedSegment = 0; // 0 = All, 1 = Following, 2 = Mine

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Tournaments',
          style: AppTextStyles.screenTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.ink),
            onPressed: () {
              context.push('/tournaments/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segment control: All / Following / Mine
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppColors.card,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  _SegmentItem(
                    title: 'All',
                    isSelected: _selectedSegment == 0,
                    onTap: () => setState(() => _selectedSegment = 0),
                  ),
                  _SegmentItem(
                    title: 'Following',
                    isSelected: _selectedSegment == 1,
                    onTap: () => setState(() => _selectedSegment = 1),
                  ),
                  _SegmentItem(
                    title: 'Mine',
                    isSelected: _selectedSegment == 2,
                    onTap: () => setState(() => _selectedSegment = 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                TournamentCard(
                  title: 'City Loft Championship',
                  organizer: 'Ahmed Loft',
                  days: '3 days',
                  schedule: 'Alternate',
                  pigeons: 20,
                  likes: 318,
                  views: '1.2k',
                  isLive: true,
                  coverGradient: AppColors.duskMesh,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => TournamentDetailScreen(
                          tournamentId: 'city-loft',
                          isOwner: _selectedSegment == 2,
                        ),
                      ),
                    );
                  },
                ),
                TournamentCard(
                  title: 'Spring Open Flyers',
                  organizer: 'Kashif Lofts',
                  days: '1 day',
                  schedule: 'Every day',
                  pigeons: 12,
                  likes: 142,
                  views: '890',
                  isLive: false,
                  coverGradient: AppColors.heroMeshSky,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const TournamentDetailScreen(
                          tournamentId: 'spring-open',
                        ),
                      ),
                    );
                  },
                ),
                TournamentCard(
                  title: 'Valley Race Cup',
                  organizer: 'Usman Club',
                  days: '5 days',
                  schedule: 'Alternate',
                  pigeons: 30,
                  likes: 560,
                  views: '2.5k',
                  isLive: false,
                  coverGradient: AppColors.dawnMesh,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const TournamentDetailScreen(
                          tournamentId: 'valley-cup',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? AppShadows.xs : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.captionBold.copyWith(
              color: isSelected ? AppColors.brand : AppColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}
