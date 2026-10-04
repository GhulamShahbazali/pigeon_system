import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class AutoEndedRecordScreen extends StatelessWidget {
  final String date;
  final String loftName;

  const AutoEndedRecordScreen({
    super.key,
    this.date = '16 Oct',
    this.loftName = 'My live record',
  });

  @override
  Widget build(BuildContext context) {
    final pigeons = [
      {'name': 'Shaheen', 'landing': '12:40 PM', 'avg': '12:40', 'returned': true},
      {'name': 'Toofan', 'landing': '01:05 PM', 'avg': '13:05', 'returned': true},
      {'name': 'Noori', 'landing': '01:12 PM', 'avg': '13:12', 'returned': true},
      {'name': 'Baaz', 'landing': 'Not returned', 'avg': '—', 'returned': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(date, style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.ink2),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Ended Banner (Auto-ended 12:00 AM)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flying ended',
                          style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Auto-ended 12:00 AM (local) · saved to My Records',
                          style: AppTextStyles.caption.copyWith(color: AppColors.white90),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pigeons Table Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Pigeon', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                  Expanded(flex: 3, child: Text('Landed', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                  Expanded(flex: 2, child: Text('Avg', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                ],
              ),
            ),

            // Pigeons Table Rows
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(
                  left: BorderSide(color: AppColors.line),
                  right: BorderSide(color: AppColors.line),
                  bottom: BorderSide(color: AppColors.line),
                ),
              ),
              child: Column(
                children: pigeons.map((p) {
                  final returned = p['returned'] as bool;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.hair)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            p['name'] as String,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: returned ? AppColors.ink : AppColors.mut,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            p['landing'] as String,
                            style: AppTextStyles.body.copyWith(
                              color: returned ? AppColors.ink : AppColors.mut,
                              fontWeight: returned ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            p['avg'] as String,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: returned ? AppColors.brand : AppColors.mut,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Subtotal / Summary for unreturned pigeons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Not returned',
                    style: AppTextStyles.body.copyWith(color: AppColors.sub, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '6 pigeons',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),

            // Total Average Card with Trophy Icon
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.brandButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final total average · 12 of 18',
                        style: AppTextStyles.caption.copyWith(color: AppColors.white90),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '13:02',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 38),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
