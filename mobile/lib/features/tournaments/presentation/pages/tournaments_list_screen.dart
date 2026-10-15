import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_card_model.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_card.dart';
import 'tournament_detail_screen.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  // Filters: All · Upcoming (coming soon) · Ongoing (live/running) · Past (finished).
  static const List<({String label, String tab})> _segments = [
    (label: 'All', tab: 'all'),
    (label: 'Upcoming', tab: 'upcoming'),
    (label: 'Ongoing', tab: 'ongoing'),
    (label: 'Past', tab: 'past'),
  ];
  int _selectedSegment = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<TournamentCardModel> _tournaments = [];

  final TournamentsRepository _repository = sl<TournamentsRepository>();

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  String get _currentTab => _segments[_selectedSegment].tab;

  Future<void> _fetchTournaments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getTournaments(tab: _currentTab);
    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _tournaments = data;
          _isLoading = false;
        });
      },
      failure: (message, code) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      },
    );
  }

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
          // Segment control: Ongoing / Past
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
                  for (int i = 0; i < _segments.length; i++)
                    _SegmentItem(
                      title: _segments[i].label,
                      isSelected: _selectedSegment == i,
                      onTap: () {
                        if (_selectedSegment != i) {
                          setState(() => _selectedSegment = i);
                          _fetchTournaments();
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Tournament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await context.push<bool>('/tournaments/create');
          if (created == true) {
            _fetchTournaments();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTournaments,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.muted, size: 54),
              const SizedBox(height: 12),
              Text(
                _currentTab == 'upcoming'
                    ? 'No upcoming tournaments.'
                    : _currentTab == 'ongoing'
                        ? 'No tournaments running right now.'
                        : _currentTab == 'past'
                            ? 'No past tournaments yet.'
                            : 'No tournaments found.',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tournaments organized by users will show up here.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _fetchTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final item = _tournaments[index];
          return TournamentCard(
            title: item.title,
            organizer: item.organizer?.displayName ?? 'Organizer',
            days: item.daysDisplay,
            schedule: item.scheduleDisplay,
            pigeons: item.pigeonCount,
            likes: item.likeCount,
            views: item.viewCount.toString(),
            isLive: item.isLive,
            isCompleted: item.status == 'completed',
            avatarUrl: item.organizer?.photoUrl,
            coverGradient: index % 2 == 0 ? AppColors.duskMesh : AppColors.heroMeshSky,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => TournamentDetailScreen(
                    tournamentId: item.id,
                  ),
                ),
              );
            },
          );
        },
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.brand : AppColors.muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
