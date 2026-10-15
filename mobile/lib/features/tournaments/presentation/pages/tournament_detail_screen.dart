import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../../data/models/tournament_detail_model.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_contact_dialog.dart';
import '../widgets/tournament_share_dialog.dart';
import '../widgets/tournament_owner_menu_dialog.dart';
import 'participant_detail_screen.dart';
import 'create_tournament_screen.dart';
import 'tournament_participants_screen.dart';
import 'add_participant_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOwner;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.isOwner = false,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  int _activeSegment = 0; // 0 = Standings, 1 = Participants, 2 = Rules
  int _selectedDayIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  TournamentDetailModel? _detail;
  List<ParticipantRowModel> _standings = [];

  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 0;

  final TournamentsRepository _repository = sl<TournamentsRepository>();

  @override
  void initState() {
    super.initState();
    _loadTournamentData();
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final detailResult = await _repository.getTournamentDetail(widget.tournamentId);
    final standingsResult = await _repository.getStandings(widget.tournamentId);

    if (!mounted) return;

    if (detailResult.isFailure) {
      setState(() {
        _errorMessage = (detailResult as dynamic).message;
        _isLoading = false;
      });
      return;
    }

    final detail = (detailResult as dynamic).data as TournamentDetailModel;
    final standings = standingsResult.isSuccess
        ? (standingsResult as dynamic).data as List<ParticipantRowModel>
        : <ParticipantRowModel>[];

    setState(() {
      _detail = detail;
      _standings = standings;
      _likeCount = detail.likeCount;
      _isFollowing = detail.isFollowing;
      _isLiked = detail.isLiked;
      _isLoading = false;
    });
  }

  Future<void> _navigateToAddParticipant() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddParticipantScreen(
          onSave: (name, phone, contact, address) async {
            final res = await _repository.addParticipant(
              widget.tournamentId,
              {
                'name': name,
                if (phone.isNotEmpty) 'phone': phone,
                if (contact.isNotEmpty) 'contact_no': contact,
                if (address.isNotEmpty) 'address': address,
              },
            );
            if (res.isSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Participant added successfully!')),
                );
                _loadTournamentData();
              }
            } else {
              if (mounted) {
                final err = (res as dynamic).message ?? 'Failed to add participant';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $err')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _openParticipantDetail(String participantId, String name, int rank) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ParticipantDetailScreen(
          participantId: participantId,
          participantName: name,
          rank: rank,
          isOwner: widget.isOwner || (_detail != null && _detail!.isOrganizer),
          tournamentId: widget.tournamentId,
        ),
      ),
    ).then((_) => _loadTournamentData());
  }

  Future<void> _showRecordFlightDialog(TournamentDetailModel t) async {
    if (_standings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add participants first to record flights.')),
      );
      return;
    }

    if (t.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament has no scheduled days.')),
      );
      return;
    }

    String selectedParticipantId = _standings.first.id;
    int selectedDayIdx = _selectedDayIndex < t.days.length ? _selectedDayIndex : 0;
    final nameCtrl = TextEditingController(text: 'Pigeon 1');
    TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
    String landingTimeText = '12:30 PM';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Record Pigeon Landing', style: AppTextStyles.h3),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Participant', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedParticipantId,
                        isExpanded: true,
                        items: _standings.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(p.name, style: AppTextStyles.bodyBold),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedParticipantId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Flight Day', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedDayIdx,
                        isExpanded: true,
                        items: t.days.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final d = entry.value;
                          return DropdownMenuItem<int>(
                            value: idx,
                            child: Text('Day ${d.dayNumber} (${d.date})', style: AppTextStyles.bodyBold),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedDayIdx = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Pigeon Name / Tag', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: AppTextStyles.bodyBold,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shaheen, 01, Blue Ring',
                      filled: true,
                      fillColor: AppColors.soft,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Landing Time', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: pickedTime,
                      );
                      if (picked != null) {
                        pickedTime = picked;
                        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                        final minute = picked.minute.toString().padLeft(2, '0');
                        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                        setSheetState(() {
                          landingTimeText = '${hour.toString().padLeft(2, '0')}:$minute $period';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.brand),
                          const SizedBox(width: 10),
                          Text(landingTimeText, style: AppTextStyles.bodyBold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Save Flight Result',
                    isLoading: isSubmitting,
                    isFullWidth: true,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final pigeonName = nameCtrl.text.trim();
                            if (pigeonName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter pigeon name')),
                              );
                              return;
                            }

                            setSheetState(() => isSubmitting = true);

                            final selectedDay = t.days[selectedDayIdx];
                            final dateParts = selectedDay.date.split('-');
                            final year = int.parse(dateParts[0]);
                            final month = int.parse(dateParts[1]);
                            final day = int.parse(dateParts[2]);

                            final landingDateTime = DateTime(
                              year,
                              month,
                              day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            final res = await _repository.recordFlight(
                              t.id,
                              selectedParticipantId,
                              {
                                'day_id': selectedDay.id,
                                'pigeon_name': pigeonName,
                                'landing_time': landingDateTime.toUtc().toIso8601String(),
                              },
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();

                            if (res.isSuccess) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Flight landing recorded successfully!')),
                                );
                                _loadTournamentData();
                              }
                            } else {
                              if (mounted) {
                                final err = (res as dynamic).message ?? 'Failed to record flight';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $err')),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_detail == null) return;
    final next = !_isLiked;
    setState(() {
      _isLiked = next;
      _likeCount += next ? 1 : -1;
    });

    if (next) {
      await _repository.likeTournament(widget.tournamentId);
    } else {
      await _repository.unlikeTournament(widget.tournamentId);
    }
  }

  Future<void> _toggleFollow() async {
    final next = !_isFollowing;
    setState(() => _isFollowing = next);

    if (next) {
      await _repository.followTournament(widget.tournamentId);
    } else {
      await _repository.unfollowTournament(widget.tournamentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    if (_errorMessage != null || _detail == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Failed to load tournament',
                    textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTournamentData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final t = _detail!;
    final isOrganizer = widget.isOwner || t.isOrganizer;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _loadTournamentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Hero section with dusk/sky gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.duskMesh,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      top: 20,
                      right: -20,
                      child: PigeonWatermark(
                        width: 190,
                        height: 190,
                        color: Color(0x24FFFFFF),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top nav bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white, size: 20),
                                  onPressed: () => Navigator.of(context).maybePop(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Row(
                                  children: [
                                    if (t.organizerContact != null && t.organizerContact!.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.phone_outlined,
                                            color: Colors.white, size: 22),
                                        onPressed: () {
                                          TournamentContactDialog.show(
                                            context,
                                            organizerName: t.organizer?.displayName ?? 'Organizer',
                                            phoneNumber: t.organizerContact!,
                                          );
                                        },
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.more_horiz_rounded,
                                          color: Colors.white, size: 24),
                                      onPressed: () {
                                        if (isOrganizer) {
                                          TournamentOwnerMenuDialog.show(
                                            context,
                                            onEdit: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => CreateTournamentScreen(
                                                    isEditing: true,
                                                    initialTitle: t.title,
                                                    initialDays: t.numDays,
                                                    initialPigeons: t.pigeonCount,
                                                    initialContact: t.organizerContact ?? '',
                                                  ),
                                                ),
                                              );
                                            },
                                            onAddParticipant: _navigateToAddParticipant,
                                            onManageParticipants: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => TournamentParticipantsScreen(
                                                    tournamentId: t.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            onDelete: () => Navigator.of(context).pop(),
                                            onShare: () {
                                              TournamentShareDialog.show(
                                                context,
                                                title: 'Share tournament',
                                                subtitle: 'Anyone can open it in PigeonFly',
                                                shareUrl: 'pigeonfly.app/t/${t.linkSlug}',
                                              );
                                            },
                                          );
                                        } else {
                                          TournamentShareDialog.show(
                                            context,
                                            title: 'Share tournament',
                                            subtitle: 'Anyone can open it in PigeonFly',
                                            shareUrl: 'pigeonfly.app/t/${t.linkSlug}',
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.title,
                              style: AppTextStyles.h2.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOrganizer
                                  ? 'You created this · ${t.pigeonCount} pigeons'
                                  : 'by ${t.organizer?.displayName ?? "Organizer"} · ${t.numDays} days · ${t.pigeonCount} pigeons',
                              style: AppTextStyles.body.copyWith(color: AppColors.white90),
                            ),
                            const SizedBox(height: 14),
                            // Hero stats row
                            Row(
                              children: [
                                _HeroStat(
                                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  iconColor: _isLiked ? AppColors.danger : Colors.white,
                                  text: '$_likeCount',
                                ),
                                const SizedBox(width: 16),
                                _HeroStat(
                                  icon: Icons.remove_red_eye_outlined,
                                  iconColor: Colors.white,
                                  text: '${t.viewCount}',
                                ),
                                const SizedBox(width: 16),
                                _HeroStat(
                                  icon: Icons.people_outline_rounded,
                                  iconColor: Colors.white,
                                  text: '${_standings.length}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Winner Champion Banner (ONLY when tournament is completed)
              if (_standings.isNotEmpty && t.status == 'completed')
                InkWell(
                  onTap: () {
                    context.push('/tournaments/winner/${t.id}?title=${Uri.encodeComponent(t.title)}');
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A1D63), Color(0xFF6D4CE6), Color(0xFF2F6BFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD66B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFF0B1020), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.status == 'completed'
                                        ? 'TOURNAMENT COMPLETED'
                                        : 'LEADERBOARD CHAMPION',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD66B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('🎉', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Winner: ${_standings.first.name} (${_standings.first.formattedAverage})',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),

              // Actions row (Follow/Record, Like, Share)
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: isOrganizer
                          ? AppButton(
                              text: 'Record Flight',
                              icon: Icons.add_rounded,
                              onPressed: () => _showRecordFlightDialog(t),
                            )
                          : AppButton(
                              text: _isFollowing ? 'Following' : 'Follow',
                              icon: _isFollowing ? Icons.check_rounded : Icons.add_circle_outline_rounded,
                              variant: _isFollowing ? AppButtonVariant.soft : AppButtonVariant.primary,
                              onPressed: _toggleFollow,
                            ),
                    ),
                    if (!isOrganizer) ...[
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isLiked ? AppColors.danger : AppColors.ink2,
                        onTap: _toggleLike,
                      ),
                    ],
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        TournamentShareDialog.show(
                          context,
                          title: 'Share tournament',
                          subtitle: 'Anyone can open it in PigeonFly',
                          shareUrl: 'pigeonfly.app/t/${t.linkSlug}',
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Segment Tabs (Standings, Participants, Rules)
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      _SegmentTab(
                        title: 'Standings',
                        isSelected: _activeSegment == 0,
                        onTap: () => setState(() => _activeSegment = 0),
                      ),
                      _SegmentTab(
                        title: 'Participants (${_standings.length})',
                        isSelected: _activeSegment == 1,
                        onTap: () => setState(() => _activeSegment = 1),
                      ),
                      _SegmentTab(
                        title: 'Rules',
                        isSelected: _activeSegment == 2,
                        onTap: () => setState(() => _activeSegment = 2),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Segment Views
              if (_activeSegment == 0) _buildStandingsTab(t),
              if (_activeSegment == 1) _buildParticipantsTab(isOrganizer),
              if (_activeSegment == 2) _buildRulesTab(t),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTab(TournamentDetailModel t) {
    return Column(
      children: [
        // Days Row
        if (t.days.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(t.days.length, (index) {
                  final day = t.days[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DayTab(
                      dayLabel: 'DAY ${day.dayNumber}',
                      dateLabel: day.date,
                      isSelected: _selectedDayIndex == index,
                      onTap: () => setState(() => _selectedDayIndex = index),
                    ),
                  );
                }),
              ),
            ),
          ),

        // Ranked Rows
        if (_standings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.leaderboard_outlined, color: AppColors.muted, size: 48),
                const SizedBox(height: 10),
                Text('No flight landings recorded yet', style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text('Results will appear here as pigeons land.', style: AppTextStyles.caption),
              ],
            ),
          )
        else
          ..._standings.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return _RankRow(
              rank: p.position ?? (idx + 1),
              name: p.name,
              meta: '${p.overallReturnedCount} birds landed',
              avg: p.formattedAverage,
              initial: p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
              gradient: idx % 3 == 0
                  ? AppColors.avatarBlue
                  : idx % 3 == 1
                      ? AppColors.avatarPurple
                      : AppColors.avatarGreen,
              onTap: () => _openParticipantDetail(p.id, p.name, p.position ?? (idx + 1)),
            );
          }),

        // Overall total average banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.brandButton,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OVERALL TOURNAMENT AVERAGE',
                      style: AppTextStyles.overline.copyWith(color: AppColors.white70)),
                  const SizedBox(height: 4),
                  Text('Calculated over returned birds',
                      style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                ],
              ),
              Text(
                t.formattedOverallAverage,
                style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab(bool isOwner) {
    return Column(
      children: [
        if (isOwner)
          InkWell(
            onTap: _navigateToAddParticipant,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                border: Border.all(color: AppColors.brand100),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('＋ Add Participant', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                        Text('Add a new player / loft to this tournament', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        if (_standings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.people_outline, color: AppColors.muted, size: 48),
                const SizedBox(height: 10),
                Text('No participants added yet', style: AppTextStyles.bodyBold),
              ],
            ),
          )
        else
          ..._standings.map((p) {
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openParticipantDetail(p.id, p.name, p.position ?? 1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    AppAvatar(name: p.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppTextStyles.bodyBold),
                          Text('Average: ${p.formattedAverage}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRulesTab(TournamentDetailModel t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tournament Rules & Details', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          Text(
            t.rules?.isNotEmpty == true
                ? t.rules!
                : '1. All pigeons must be released at the official fly time.\n2. Only pigeons returning before sunset will be counted.\n3. The participant with highest flight average duration wins.',
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _HeroStat({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.color = AppColors.ink2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
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

class _DayTab extends StatelessWidget {
  final String dayLabel;
  final String dateLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayTab({
    required this.dayLabel,
    required this.dateLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.brand : AppColors.line),
        ),
        child: Column(
          children: [
            Text(dayLabel,
                style: AppTextStyles.overline.copyWith(
                    color: isSelected ? AppColors.brand : AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
            Text(dateLabel,
                style: AppTextStyles.captionBold.copyWith(
                    color: isSelected ? AppColors.brand : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final String meta;
  final String avg;
  final String initial;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.meta,
    required this.avg,
    required this.initial,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rank == 1 ? const Color(0xFFFFD700) : AppColors.soft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: AppTextStyles.captionBold.copyWith(
                      color: rank == 1 ? Colors.brown.shade900 : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppAvatar(name: name, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.bodyBold),
                      Text(meta, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Text(avg, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
