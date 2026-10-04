import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import 'add_record_screen.dart';
import 'live_record_screen.dart';
import 'private_record_detail_screen.dart';
import 'auto_ended_record_screen.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  int _selectedTab = 0; // 0 = My records, 1 = Live now
  bool _isUserLive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar matching wireframe (.bar with .gbtn.brand plus)
            Container(
              color: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Records',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 23),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const AddRecordScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: AppShadows.brandButton,
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Segmented tab: My records / Live now
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
                    title: 'My records',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _SegmentItem(
                    title: 'Live now',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
          ),

          // Body based on tab
          Expanded(
            child: _selectedTab == 0 ? _buildMyRecords() : _buildLiveNowList(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMyRecords() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // You're live banner
        if (_isUserLive)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const LiveRecordScreen(isOwner: true, loftName: 'My live record')),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E3A26), Color(0xFF12B76A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("You're live now", style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
                        Text('12 of 18 landed · 870 watching', style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isUserLive = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white28,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('End', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Record Card 1 (Live)
        _buildRecordCard(
          date: 'Today · 16 Oct',
          isLive: true,
          flown: 18,
          flyTime: '06:00',
          avg: '13:04',
          likes: 54,
          views: '870',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const LiveRecordScreen(isOwner: true)),
            );
          },
        ),

        // Record Card 2 (Private)
        _buildRecordCard(
          date: '15 Oct',
          isLive: false,
          flown: 20,
          flyTime: '06:10',
          avg: '12:50',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const PrivateRecordDetailScreen(date: '15 Oct')),
            );
          },
        ),

        // Record Card 3 (Auto-ended history from yesterday)
        _buildRecordCard(
          date: '14 Oct',
          isLive: false,
          flown: 18,
          flyTime: '06:00',
          avg: '13:02',
          likes: 42,
          views: '610',
          isAutoEnded: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const AutoEndedRecordScreen(date: '14 Oct')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveNowList() {
    final liveFlyers = [
      {'name': "Ahmed's loft", 'sub': '12 of 18 landed · 870 watching', 'avg': '13:02', 'initial': 'A', 'grad': AppColors.avatarBlue},
      {'name': 'Kashif Ali', 'sub': '5 of 14 landed · 210 watching', 'avg': '11:40', 'initial': 'K', 'grad': AppColors.avatarPurple},
      {'name': 'Usman Tariq', 'sub': '9 of 10 landed · 440 watching', 'avg': '12:15', 'initial': 'U', 'grad': AppColors.avatarGreen},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            'People you follow who are flying live right now.',
            style: AppTextStyles.body.copyWith(color: AppColors.sub, fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        ...liveFlyers.map((flyer) {
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => LiveRecordScreen(loftName: flyer['name'] as String, isOwner: false)),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.xs,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Green left indicator bar (border-left: 3.5px solid var(--ok) from wireframe)
                    Container(
                      width: 4,
                      height: 72,
                      color: AppColors.ok,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                AppAvatar(
                                  text: flyer['initial'] as String,
                                  size: 42,
                                  gradient: flyer['grad'] as LinearGradient,
                                ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.ok,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(flyer['name'] as String, style: AppTextStyles.bodyBold),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ok50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.ok, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(flyer['sub'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(flyer['avg'] as String, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                      Text('avg', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}),
],
);
  }

  Widget _buildRecordCard({
    required String date,
    required bool isLive,
    required int flown,
    required String flyTime,
    required String avg,
    int? likes,
    String? views,
    bool isAutoEnded = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.xs,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: AppTextStyles.bodyBold),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.ok50 : isAutoEnded ? AppColors.soft : AppColors.soft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.ok,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ] else if (isAutoEnded) ...[
                        const Icon(Icons.check_circle_outline_rounded, size: 11, color: AppColors.sub),
                        const SizedBox(width: 4),
                      ] else ...[
                        const Icon(Icons.lock_rounded, size: 10, color: AppColors.sub),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isLive ? 'LIVE' : isAutoEnded ? 'Ended' : 'Private',
                        style: AppTextStyles.captionBold.copyWith(
                          color: isLive ? AppColors.ok : AppColors.sub,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.mut),
                const SizedBox(width: 4),
                Text('$flown flown', style: AppTextStyles.body),
                const SizedBox(width: 14),
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.mut),
                const SizedBox(width: 4),
                Text(flyTime, style: AppTextStyles.body),
                const Spacer(),
                Text('Avg $avg', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
              ],
            ),
            if (likes != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.hair)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 16),
                    const SizedBox(width: 6),
                    Text('$likes', style: AppTextStyles.captionBold.copyWith(color: AppColors.danger)),
                    const SizedBox(width: 14),
                    const Icon(Icons.remove_red_eye_outlined, color: AppColors.mut, size: 16),
                    const SizedBox(width: 6),
                    Text(views ?? '0', style: AppTextStyles.captionBold.copyWith(color: AppColors.sub)),
                  ],
                ),
              ),
            ],
          ],
        ),
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
