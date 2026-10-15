import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/tournament_card_model.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_card.dart';
import 'tournament_detail_screen.dart';

class UserTournamentsScreen extends StatefulWidget {
  final String? initialTab;

  const UserTournamentsScreen({super.key, this.initialTab});

  @override
  State<UserTournamentsScreen> createState() => _UserTournamentsScreenState();
}

class _UserTournamentsScreenState extends State<UserTournamentsScreen> {
  late int _selectedSegment; // 0 = All (mine), 1 = Followed
  bool _isLoading = true;
  String? _errorMessage;
  List<TournamentCardModel> _tournaments = [];

  final TournamentsRepository _repository = sl<TournamentsRepository>();

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialTab == 'followed' ? 1 : 0;
    _fetchTournaments();
  }

  String get _currentTab => _selectedSegment == 0 ? 'mine' : 'following';

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
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          s.myTournaments,
          style: AppTextStyles.screenTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          // Segment control: All / Followed
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
                    title: s.tabAll,
                    isSelected: _selectedSegment == 0,
                    onTap: () {
                      if (_selectedSegment != 0) {
                        setState(() => _selectedSegment = 0);
                        _fetchTournaments();
                      }
                    },
                  ),
                  _SegmentItem(
                    title: s.followedTab,
                    isSelected: _selectedSegment == 1,
                    onTap: () {
                      if (_selectedSegment != 1) {
                        setState(() => _selectedSegment = 1);
                        _fetchTournaments();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildBody(s),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(s.newTournament, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await context.push<bool>('/tournaments/create');
          if (created == true) {
            _fetchTournaments();
          }
        },
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.mut),
              const SizedBox(height: 12),
              Text(s.failedLoadTournaments, style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(_errorMessage!, style: AppTextStyles.caption, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTournaments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_tournaments.isEmpty) {
      final isMine = _selectedSegment == 0;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMine ? Icons.emoji_events_outlined : Icons.bookmark_border_rounded,
                  size: 36,
                  color: AppColors.mut,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMine ? s.noTournamentsCreated : s.noFollowedTournaments,
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isMine
                    ? s.tournamentsCreatedHint
                    : s.followedTournamentsHint,
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
            organizer: item.organizer?.displayName ?? s.organizer,
            days: item.daysDisplay,
            schedule: item.scheduleDisplay,
            pigeons: item.pigeonCount,
            likes: item.likeCount,
            views: item.viewCount.toString(),
            isLive: item.isLive,
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
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(
              color: isSelected ? AppColors.ink : AppColors.mut,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
