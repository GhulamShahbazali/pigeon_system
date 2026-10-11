import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

class RecordsSearchScreen extends StatefulWidget {
  const RecordsSearchScreen({super.key});

  @override
  State<RecordsSearchScreen> createState() => _RecordsSearchScreenState();
}

class _RecordsSearchScreenState extends State<RecordsSearchScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _liveFlyers = [
    {
      'name': 'Ali Hamza',
      'handle': '@ali.hamza',
      'initial': 'A',
      'gradient': AppColors.avatarGold,
      'status': 'live now · 2 / 3 back',
      'avg': '6:52',
    },
    {
      'name': 'Ali Raza',
      'handle': '@aliraza_pk',
      'initial': 'A',
      'gradient': AppColors.avatarBlue,
      'status': 'live now · 4 / 6 back',
      'avg': '5:40',
    },
    {
      'name': 'Wali Ullah',
      'handle': '@waliullah',
      'initial': 'W',
      'gradient': AppColors.avatarPurple,
      'status': 'live now · 1 / 2 back',
      'avg': '7:10',
    },
    {
      'name': 'Ahmed Loft',
      'handle': '@ahmedloft',
      'initial': 'A',
      'gradient': AppColors.avatarGreen,
      'status': 'live now · 12 / 18 back',
      'avg': '13:02',
    },
    {
      'name': 'Kashif Ali',
      'handle': '@kashif_ali',
      'initial': 'K',
      'gradient': AppColors.avatarBlue,
      'status': 'live now · 5 / 14 back',
      'avg': '11:40',
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
    final filtered = _liveFlyers.where((item) {
      if (query.isEmpty) return true;
      return (item['name'] as String).toLowerCase().contains(query) ||
          (item['handle'] as String).toLowerCase().contains(query);
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
            // Search field matching wireframe 2b (.search.on)
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
                          hintText: 'Search live flyer by name or @handle…',
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

            // Section Header (.sh2 Live records · by flyer)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text(
                'Live records · by flyer',
                style: AppTextStyles.labelUppercase,
              ),
            ),

            // Result List matching wireframe (.sres with live dot and avg)
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.mut),
                          const SizedBox(height: 12),
                          Text(
                            'No live flyers found',
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
                              context.push('/records/live');
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
                                  AppAvatar(
                                    text: item['initial'] as String,
                                    size: 44,
                                    gradient: item['gradient'] as LinearGradient,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item['name'] as String,
                                              style: AppTextStyles.bodyBold,
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: AppColors.danger,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${item['handle']} · ${item['status']}',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(item['avg'] as String, style: AppTextStyles.h4),
                                      Text(
                                        'avg',
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
