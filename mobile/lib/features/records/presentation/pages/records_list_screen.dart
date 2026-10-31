import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/records_repository.dart';
import 'add_record_screen.dart';
import 'live_record_screen.dart';
import 'private_record_detail_screen.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  int _selectedTab = 0; // 0 = My records, 1 = Live now
  bool _isLoading = true;
  String? _errorMessage;

  List<PersonalRecordModel> _myRecords = [];
  List<LiveRecordPreviewModel> _liveNowRecords = [];

  final RecordsRepository _repository = sl<RecordsRepository>();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_selectedTab == 0) {
      final res = await _repository.getMyRecords();
      if (!mounted) return;
      res.when(
        success: (data) {
          setState(() {
            _myRecords = data;
            _isLoading = false;
          });
        },
        failure: (msg, _) {
          setState(() {
            _errorMessage = msg;
            _isLoading = false;
          });
        },
      );
    } else {
      final res = await _repository.getLiveNow();
      if (!mounted) return;
      res.when(
        success: (data) {
          setState(() {
            _liveNowRecords = data;
            _isLoading = false;
          });
        },
        failure: (msg, _) {
          setState(() {
            _errorMessage = msg;
            _isLoading = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Container(
              color: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    s.recordsTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 23),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => context.push('/records/search'),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Icon(Icons.search_rounded, color: AppColors.ink2, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (ctx) => const AddRecordScreen()),
                      );
                      if (created == true) {
                        _fetchRecords();
                      }
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
                      title: s.myRecordsTab,
                      isSelected: _selectedTab == 0,
                      onTap: () {
                        if (_selectedTab != 0) {
                          setState(() => _selectedTab = 0);
                          _fetchRecords();
                        }
                      },
                    ),
                    _SegmentItem(
                      title: s.liveNow,
                      isSelected: _selectedTab == 1,
                      onTap: () {
                        if (_selectedTab != 1) {
                          setState(() => _selectedTab = 1);
                          _fetchRecords();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Body based on tab
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _fetchRecords,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.danger, size: 48),
                                  const SizedBox(height: 12),
                                  Text(_errorMessage!,
                                      textAlign: TextAlign.center, style: AppTextStyles.body),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchRecords,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brand),
                                    child: Text(s.tryAgain,
                                        style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _selectedTab == 0
                            ? _buildMyRecords(s)
                            : _buildLiveNowList(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRecords(AppStrings s) {
    if (_myRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_alt_outlined, color: AppColors.muted, size: 48),
              const SizedBox(height: 12),
              Text(s.noFlightRecords, style: AppTextStyles.bodyBold),
              const SizedBox(height: 6),
              Text(s.logLoftHint,
                  style: AppTextStyles.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final liveRecord = _myRecords.cast<PersonalRecordModel?>().firstWhere(
          (r) => r?.isLive == true,
          orElse: () => null,
        );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // You're live banner
        if (liveRecord != null)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) =>
                        LiveRecordScreen(isOwner: true, loftName: 'My Live Record')),
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
                        Text(s.youreLive,
                            style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
                        Text(s.landedOf(liveRecord.returnedCount, liveRecord.totalPigeons),
                            style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        ..._myRecords.map((r) {
          return _buildRecordCard(
            s: s,
            date: r.recordDate,
            isLive: r.isLive,
            flown: r.totalPigeons,
            flyTime: r.formattedFlyTime,
            avg: r.formattedAverage,
            likes: r.likeCount,
            views: r.viewCount.toString(),
            onTap: () {
              if (r.isLive) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => LiveRecordScreen(recordId: r.id, isOwner: true)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (ctx) => PrivateRecordDetailScreen(date: r.recordDate)),
                );
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildLiveNowList(AppStrings s) {
    if (_liveNowRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_tethering, color: AppColors.muted, size: 48),
              const SizedBox(height: 12),
              Text(s.noFlyersLive, style: AppTextStyles.bodyBold),
              const SizedBox(height: 6),
              Text(s.noFlyersLiveHint,
                  style: AppTextStyles.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _liveNowRecords.length,
      itemBuilder: (context, index) {
        final flyer = _liveNowRecords[index];
        final name = flyer.owner?.displayName ?? s.flyer;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => LiveRecordScreen(
                  recordId: flyer.id,
                  loftName: "$name's loft",
                  isOwner: false,
                ),
              ),
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
                                name: name,
                                imageUrl: flyer.owner?.photoUrl,
                                size: 42,
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
                                Text(name, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  s.landedOf(flyer.returnedCount, flyer.totalPigeons),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.ok.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.live,
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.ok,
                                fontSize: 11,
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
          ),
        );
      },
    );
  }

  Widget _buildRecordCard({
    required AppStrings s,
    required String date,
    required bool isLive,
    required int flown,
    required String flyTime,
    required String avg,
    int? likes,
    String? views,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(date, style: AppTextStyles.cardTitle),
                    const Spacer(),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ok.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.liveNowBadge,
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.ok,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.privateLabel,
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoPill(label: s.pigeons, value: '$flown'),
                    const SizedBox(width: 8),
                    _InfoPill(label: s.flyTimeLabel, value: flyTime),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s.average, style: AppTextStyles.caption),
                        Text(avg,
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.captionBold),
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
