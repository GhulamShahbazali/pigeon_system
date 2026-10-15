import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_card_model.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_card.dart';
import 'tournament_detail_screen.dart';

/// Tournaments organized by a specific user (shown from their profile).
class UserTournamentsListScreen extends StatefulWidget {
  final String userId;
  final String title;

  const UserTournamentsListScreen({super.key, required this.userId, this.title = 'Tournaments'});

  @override
  State<UserTournamentsListScreen> createState() => _UserTournamentsListScreenState();
}

class _UserTournamentsListScreenState extends State<UserTournamentsListScreen> {
  final TournamentsRepository _repo = sl<TournamentsRepository>();
  List<TournamentCardModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getUserTournaments(widget.userId);
    if (!mounted) return;
    res.when(
      success: (data) => setState(() {
        _items = data;
        _loading = false;
      }),
      failure: (m, __) => setState(() {
        _error = m;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: AppTextStyles.screenTitle),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body)));
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.emoji_events_outlined, size: 54, color: AppColors.muted),
        const SizedBox(height: 12),
        Center(child: Text('No tournaments yet', style: AppTextStyles.cardTitle)),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final t = _items[i];
        return TournamentCard(
          title: t.title,
          organizer: t.organizer?.displayName ?? 'Organizer',
          avatarUrl: t.organizer?.photoUrl,
          days: t.daysDisplay,
          schedule: t.scheduleDisplay,
          pigeons: t.pigeonCount,
          likes: t.likeCount,
          views: t.viewCount.toString(),
          isLive: t.isLive,
          isCompleted: t.status == 'completed',
          coverGradient: i % 2 == 0 ? AppColors.duskMesh : AppColors.heroMeshSky,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id)),
          ),
        );
      },
    );
  }
}
