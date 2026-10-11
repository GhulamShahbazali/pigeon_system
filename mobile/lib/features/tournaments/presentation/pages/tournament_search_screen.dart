import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class TournamentSearchScreen extends StatefulWidget {
  const TournamentSearchScreen({super.key});

  @override
  State<TournamentSearchScreen> createState() => _TournamentSearchScreenState();
}

class _TournamentSearchScreenState extends State<TournamentSearchScreen> {
  final _searchController = TextEditingController();
  int _selectedScope = 0; // 0: All, 1: Live, 2: Upcoming, 3: Ended

  final List<String> _scopes = ['All', 'Live', 'Upcoming', 'Ended'];

  final List<Map<String, dynamic>> _tournaments = [
    {
      'id': 'valley-cup',
      'title': 'Valley Cup 2026',
      'isLive': true,
      'status': 'Live',
      'owner': '@ahmedloft',
      'duration': '7 days',
      'followers': 312,
      'gradient': AppColors.heroMeshSky,
    },
    {
      'id': 'valley-open',
      'title': 'Valley Open Spring',
      'isLive': false,
      'status': 'Upcoming',
      'owner': '@rashid_pk',
      'duration': '5 days',
      'followers': 88,
      'gradient': AppColors.duskMesh,
    },
    {
      'id': 'city-loft',
      'title': 'City Loft Championship',
      'isLive': true,
      'status': 'Live',
      'owner': '@ahmedloft',
      'duration': '3 days',
      'followers': 640,
      'gradient': AppColors.dawnMesh,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _tournaments.where((item) {
      final matchesQuery = query.isEmpty ||
          (item['title'] as String).toLowerCase().contains(query) ||
          (item['owner'] as String).toLowerCase().contains(query);

      final matchesScope = _selectedScope == 0 ||
          (_selectedScope == 1 && item['isLive'] == true) ||
          (_selectedScope == 2 && item['status'] == 'Upcoming') ||
          (_selectedScope == 3 && item['status'] == 'Ended');

      return matchesQuery && matchesScope;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Search', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field matching wireframe 1b (.search.on)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _searchController.text.isNotEmpty ? AppColors.brand : AppColors.line,
                    width: _searchController.text.isNotEmpty ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 20, color: AppColors.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.bodyBold,
                        decoration: InputDecoration(
                          hintText: 'Search tournaments…',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.mut,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Scope tabs (.scopetabs with .st chips: All, Live, Upcoming, Ended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _scopes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    final isSelected = _selectedScope == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedScope = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brand : AppColors.soft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.brand : AppColors.line,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.ink2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Section Header (.sh2 Tournaments · N results)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'Tournaments · ${filtered.length} ${filtered.length == 1 ? 'result' : 'results'}',
                style: AppTextStyles.labelUppercase,
              ),
            ),

            // Results List (.sres matching wireframe)
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.mut),
                          const SizedBox(height: 12),
                          Text(
                            'No tournaments found',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink2),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              context.push('/tournaments/detail/${item['id']}');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                                boxShadow: AppShadows.xs,
                              ),
                              child: Row(
                                children: [
                                  // Gradient Thumbnail (.thumb)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: item['gradient'] as LinearGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: AppTextStyles.bodyBold,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (item['isLive'] == true) ...[
                                              Container(
                                                width: 7,
                                                height: 7,
                                                margin: const EdgeInsets.only(right: 5),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.danger,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Text(
                                                'Live · ',
                                                style: AppTextStyles.captionBold.copyWith(color: AppColors.danger),
                                              ),
                                            ] else ...[
                                              Text(
                                                '${item['status']} · ',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                              ),
                                            ],
                                            Text(
                                              'by ${item['owner']} · ${item['duration']}',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${item['followers']}', style: AppTextStyles.h4),
                                      Text(
                                        'followers',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
