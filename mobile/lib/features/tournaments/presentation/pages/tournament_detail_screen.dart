import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../widgets/tournament_contact_dialog.dart';
import '../widgets/tournament_share_dialog.dart';
import '../widgets/tournament_owner_menu_dialog.dart';
import 'participant_detail_screen.dart';
import 'create_tournament_screen.dart';
import 'tournament_participants_screen.dart';

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
  int _selectedDay = 0; // 0 = Day 1, 1 = Day 2, 2 = Day 3
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 318;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
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
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(context).maybePop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 22),
                                onPressed: () {
                                  TournamentContactDialog.show(
                                    context,
                                    organizerName: 'Ahmed Loft',
                                    phoneNumber: '+92 300 1234567',
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                                onPressed: () {
                                  if (widget.isOwner) {
                                    TournamentOwnerMenuDialog.show(
                                      context,
                                      onEdit: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => const CreateTournamentScreen(
                                              isEditing: true,
                                              initialTitle: 'City Loft Championship',
                                              initialDays: 3,
                                              initialPigeons: 20,
                                              initialFlyTime: '06:00 AM',
                                              initialEndTime: '06:00 PM',
                                              initialStartDate: '16 Oct 2026',
                                              initialContact: '+92 300 1234567',
                                            ),
                                          ),
                                        );
                                      },
                                      onManageParticipants: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => const TournamentParticipantsScreen(),
                                          ),
                                        );
                                      },
                                      onDelete: () {
                                        Navigator.of(context).pop();
                                      },
                                      onShare: () {
                                        TournamentShareDialog.show(
                                          context,
                                          title: 'Share tournament',
                                          subtitle: 'Anyone can open it — in the app, or install first',
                                          shareUrl: 'pigeonfly.app/t/city-loft',
                                        );
                                      },
                                    );
                                  } else {
                                    TournamentShareDialog.show(
                                      context,
                                      title: 'Share tournament',
                                      subtitle: 'Anyone can open it — in the app, or install first',
                                      shareUrl: 'pigeonfly.app/t/city-loft',
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
                        'City Loft Championship',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isOwner
                            ? 'You created this · 20 pigeons'
                            : 'by Ahmed Loft · 3 days · 20 pigeons',
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
                          const _HeroStat(
                            icon: Icons.remove_red_eye_outlined,
                            iconColor: Colors.white,
                            text: '1.2k',
                          ),
                          const SizedBox(width: 16),
                          const _HeroStat(
                            icon: Icons.people_outline_rounded,
                            iconColor: Colors.white,
                            text: '64',
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

            // Actions row (Follow/Record, Like, Share)
            Container(
              color: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: widget.isOwner
                        ? AppButton(
                            text: 'Record Day 2',
                            icon: Icons.add_rounded,
                            onPressed: () {
                              context.push('/tournaments/record-day');
                            },
                          )
                        : AppButton(
                            text: _isFollowing ? 'Following' : 'Follow',
                            icon: _isFollowing ? Icons.check_rounded : Icons.add_circle_outline_rounded,
                            variant: _isFollowing ? AppButtonVariant.soft : AppButtonVariant.primary,
                            onPressed: () {
                              setState(() => _isFollowing = !_isFollowing);
                            },
                          ),
                  ),
                  if (!widget.isOwner) ...[
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isLiked ? AppColors.danger : AppColors.ink2,
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                          _likeCount += _isLiked ? 1 : -1;
                        });
                      },
                    ),
                  ],
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    onTap: () {
                      TournamentShareDialog.show(
                        context,
                        title: 'Share tournament',
                        subtitle: 'Anyone can open it — in the app, or install first',
                        shareUrl: 'pigeonfly.app/t/city-loft',
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
                      title: 'Participants',
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

            // Body based on segment
            if (_activeSegment == 0) _buildStandingsView()
            else if (_activeSegment == 1) _buildParticipantsView()
            else _buildRulesView(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsView() {
    return Column(
      children: [
        // Day tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _DayTab(
                  dayLabel: 'DAY 1',
                  dateLabel: '16 Oct',
                  isSelected: _selectedDay == 0,
                  onTap: () => setState(() => _selectedDay = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DayTab(
                  dayLabel: 'DAY 2',
                  dateLabel: '18 Oct',
                  isSelected: _selectedDay == 1,
                  onTap: () => setState(() => _selectedDay = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DayTab(
                  dayLabel: 'DAY 3',
                  dateLabel: '20 Oct',
                  isSelected: _selectedDay == 2,
                  onTap: () => setState(() => _selectedDay = 2),
                ),
              ),
            ],
          ),
        ),

        // Ranked Rows
        _RankRow(
          rank: 1,
          name: 'Bilal Raza',
          meta: 'Shaheen · 12:40 PM',
          avg: '12:40',
          initial: 'B',
          gradient: AppColors.avatarBlue,
          onTap: () => _openParticipantDetail('Bilal Raza', 1),
        ),
        _RankRow(
          rank: 2,
          name: 'Kashif Ali',
          meta: 'Toofan · 01:05 PM',
          avg: '13:05',
          initial: 'K',
          gradient: AppColors.avatarPurple,
          onTap: () => _openParticipantDetail('Kashif Ali', 2),
        ),
        _RankRow(
          rank: 3,
          name: 'Usman Tariq',
          meta: 'Noori · 01:20 PM',
          avg: '13:20',
          initial: 'U',
          gradient: AppColors.avatarGreen,
          onTap: () => _openParticipantDetail('Usman Tariq', 3),
        ),

        // Subtotal
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day ${_selectedDay + 1} total average', style: AppTextStyles.bodyBold),
              Text('13:01', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
            ],
          ),
        ),

        // Overall total average banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Text('Overall total average', style: AppTextStyles.caption.copyWith(color: AppColors.white90, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('13:10', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                ],
              ),
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsView() {
    final participants = [
      {'pos': 1, 'name': 'Bilal Raza', 'info': '3 pigeons · overall 13:10', 'initial': 'B', 'grad': AppColors.avatarBlue},
      {'pos': 2, 'name': 'Kashif Ali', 'info': '3 pigeons · overall 13:42', 'initial': 'K', 'grad': AppColors.avatarPurple},
      {'pos': 3, 'name': 'Usman Tariq', 'info': '2 pigeons · overall 14:05', 'initial': 'U', 'grad': AppColors.avatarGreen},
      {'pos': 4, 'name': 'Sohail Khan', 'info': '3 pigeons · overall 14:20', 'initial': 'S', 'grad': AppColors.avatarGold},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: participants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = participants[idx];
        return InkWell(
          onTap: () => _openParticipantDetail(item['name'] as String, item['pos'] as int),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.xs,
            ),
            child: Row(
              children: [
                Text('${item['pos']}', style: AppTextStyles.h4.copyWith(color: AppColors.mut)),
                const SizedBox(width: 14),
                AppAvatar(
                  text: item['initial'] as String,
                  size: 40,
                  gradient: item['grad'] as LinearGradient,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String, style: AppTextStyles.bodyBold),
                      const SizedBox(height: 2),
                      Text(item['info'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mut),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tournament Rules', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Text(
            '1. All pigeons must take flight strictly at 06:00 AM on each designated tournament day.\n\n'
            '2. Landing time will only be counted when the pigeon enters the loft or settles securely on the roof trap.\n\n'
            '3. Any pigeon not returned by sunset/end time will receive zero time points.\n\n'
            '4. Overall standings are computed via the average fly duration across all scheduled days.',
            style: AppTextStyles.body.copyWith(color: AppColors.ink2, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _openParticipantDetail(String name, int rank) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ParticipantDetailScreen(
          participantName: name,
          rank: rank,
          isOwner: widget.isOwner,
        ),
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
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, color: color ?? AppColors.ink2, size: 20),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.brand : AppColors.line),
          boxShadow: isSelected ? AppShadows.sm : AppShadows.xs,
        ),
        child: Column(
          children: [
            Text(
              dayLabel,
              style: AppTextStyles.labelUppercase.copyWith(
                color: isSelected ? AppColors.white90 : AppColors.mut,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
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
  final LinearGradient gradient;
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
    Color medalBg;
    if (rank == 1) {
      medalBg = AppColors.amber;
    } else if (rank == 2) {
      medalBg = const Color(0xFF9E9E9E);
    } else {
      medalBg = const Color(0xFFCD7F32);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: medalBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('$rank', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            AppAvatar(text: initial, size: 36, gradient: gradient),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(meta, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(avg, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                Text('avg', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
