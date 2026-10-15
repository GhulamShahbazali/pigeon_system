import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/tournament_detail_model.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_contact_dialog.dart';
import '../widgets/tournament_share_dialog.dart';

class TournamentWinnerScreen extends StatefulWidget {
  final String tournamentId;
  final String? tournamentTitle;

  const TournamentWinnerScreen({
    super.key,
    required this.tournamentId,
    this.tournamentTitle,
  });

  @override
  State<TournamentWinnerScreen> createState() => _TournamentWinnerScreenState();
}

class _TournamentWinnerScreenState extends State<TournamentWinnerScreen>
    with SingleTickerProviderStateMixin {
  final TournamentsRepository _repository = sl<TournamentsRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  TournamentDetailModel? _detail;
  List<ParticipantRowModel> _standings = [];

  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initParticles();
    _loadWinnerData();
  }

  void _initParticles() {
    final colors = [
      const Color(0xFFFFD66B),
      AppColors.brand,
      AppColors.ok,
      AppColors.danger,
      Colors.white,
      const Color(0xFF6D4CE6),
    ];

    for (int i = 0; i < 35; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          speed: 0.2 + _random.nextDouble() * 0.4,
          size: 6.0 + _random.nextDouble() * 6.0,
          color: colors[_random.nextInt(colors.length)],
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          delay: _random.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadWinnerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final detailRes = await _repository.getTournamentDetail(widget.tournamentId);
    final standingsRes = await _repository.getStandings(widget.tournamentId);

    if (!mounted) return;

    if (detailRes.isFailure) {
      setState(() {
        _errorMessage = (detailRes as dynamic).message;
        _isLoading = false;
      });
      return;
    }

    final detail = (detailRes as dynamic).data as TournamentDetailModel;
    final standings = standingsRes.isSuccess
        ? (standingsRes as dynamic).data as List<ParticipantRowModel>
        : <ParticipantRowModel>[];

    // Sort descending by average duration to ensure winner is rank 1
    standings.sort((a, b) => (b.overallAvgSeconds ?? 0).compareTo(a.overallAvgSeconds ?? 0));

    setState(() {
      _detail = detail;
      _standings = standings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD66B)),
        ),
      );
    }

    if (_errorMessage != null || _detail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFD66B), size: 54),
                const SizedBox(height: 14),
                Text(
                  _errorMessage ?? 'Failed to load winner information',
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadWinnerData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                  child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tournament = _detail!;
    final winner = _standings.isNotEmpty ? _standings.first : null;
    final title = widget.tournamentTitle ?? tournament.title;
    final winnerContact = winner?.contactNo ??
        winner?.phone ??
        tournament.organizerContact ??
        '+92 300 1234567';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Stack(
        children: [
          // Background Gradient (Mesh from hi-fi wireframe)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF2F6BFF),
                  Color(0xFF1E49B8),
                  Color(0xFF0B1020),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),

          // Animated Confetti Canvas
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confettiController.value,
                  particles: _particles,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top HUD Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Crown & Champion Tagline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFFD66B), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'CHAMPION',
                              style: TextStyle(
                                color: const Color(0xFFFFD66B),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFFD66B), size: 18),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Winner Avatar with Conic Golden Ring & Trophy Badge
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFFFFE08A),
                                    Color(0xFFE6A100),
                                    Color(0xFFFFD66B),
                                    Color(0xFFB87400),
                                    Color(0xFFFFE08A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFC33C).withValues(alpha: 0.45),
                                    blurRadius: 40,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0B1020),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: ClipOval(
                                  child: winner != null && winner.photoUrl != null
                                      ? Image.network(
                                          winner.photoUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF8FB4FF), Color(0xFF2F6BFF)],
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            winner?.name.isNotEmpty == true
                                                ? winner!.name[0].toUpperCase()
                                                : 'W',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 48,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -8,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD66B), Color(0xFFE6A100)],
                                  ),
                                  border: Border.all(color: const Color(0xFF0B1020), width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFF0B1020),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Winner Name
                        Text(
                          winner?.name ?? 'Champion Flyer',
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),

                        // Winner Meta
                        Text(
                          '1st of ${_standings.length} participants · ${tournament.numDays} days tournament',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Big Average Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Text(
                                winner?.formattedAverage ?? '0h 00m',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'OVERALL AVERAGE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          '🕊️ ${winner?.overallReturnedCount ?? 0} pigeons completed flight',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        // Podium (Top 3) if multiple participants exist
                        if (_standings.length >= 2) ...[
                          const SizedBox(height: 24),
                          _buildPodiumSection(),
                        ],

                        const SizedBox(height: 20),

                        // Contact Card (Call & WhatsApp)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  TournamentContactDialog.show(
                                    context,
                                    organizerName: winner?.name ?? 'Winner',
                                    phoneNumber: winnerContact,
                                  );
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.phone_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WINNER CONTACT',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      winnerContact,
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: AppColors.ink,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  TournamentContactDialog.show(
                                    context,
                                    organizerName: winner?.name ?? 'Winner',
                                    phoneNumber: winnerContact,
                                  );
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366), // WhatsApp Green
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.chat_bubble_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Share Result Button
                        InkWell(
                          onTap: () {
                            TournamentShareDialog.show(
                              context,
                              title: 'Share Champion Result 🎉',
                              subtitle:
                                  '${winner?.name ?? "Champion"} won ${tournament.title} with average ${winner?.formattedAverage ?? ""}',
                              shareUrl: 'pigeonfly.app/t/${tournament.linkSlug}',
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.26)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_outlined,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Share Result',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection() {
    final p1 = _standings[0];
    final p2 = _standings.length > 1 ? _standings[1] : null;
    final p3 = _standings.length > 2 ? _standings[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (p2 != null)
          Expanded(
            child: _buildPodiumColumn(
              rank: '🥈 2',
              participant: p2,
              height: 120,
              gradient: AppColors.duskMesh,
              isFirst: false,
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 8),

        // 1st Place (Winner Center)
        Expanded(
          child: _buildPodiumColumn(
            rank: '🥇 1',
            participant: p1,
            height: 144,
            gradient: AppColors.heroMeshSky,
            isFirst: true,
          ),
        ),

        const SizedBox(width: 8),

        // 3rd Place
        if (p3 != null)
          Expanded(
            child: _buildPodiumColumn(
              rank: '🥉 3',
              participant: p3,
              height: 104,
              gradient: AppColors.dawnMesh,
              isFirst: false,
            ),
          )
        else
          const Spacer(),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required String rank,
    required ParticipantRowModel participant,
    required double height,
    required Gradient gradient,
    required bool isFirst,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFFFFD66B).withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: isFirst
              ? const Color(0xFFFFD66B).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            text: participant.name,
            size: 34,
            gradient: gradient,
          ),
          const SizedBox(height: 6),
          Text(
            rank,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            participant.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            participant.formattedAverage,
            style: const TextStyle(
              color: Color(0xFFFFD66B),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final double delay;

  _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final adjustedProgress = (progress + p.delay) % 1.0;
      final y = adjustedProgress * size.height;
      final x = p.x * size.width + sin(adjustedProgress * 6 * pi) * 20;

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(adjustedProgress * p.rotationSpeed * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
