import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrivateRecordDetailScreen extends StatefulWidget {
  final String date;

  const PrivateRecordDetailScreen({
    super.key,
    this.date = '15 Oct',
  });

  @override
  State<PrivateRecordDetailScreen> createState() => _PrivateRecordDetailScreenState();
}

class _PrivateRecordDetailScreenState extends State<PrivateRecordDetailScreen> {
  bool _isLive = false;

  final List<Map<String, String>> _pigeons = [
    {'name': 'Shaheen', 'landing': '12:30 PM', 'avg': '12:30'},
    {'name': 'Toofan', 'landing': '12:58 PM', 'avg': '12:58'},
    {'name': 'Baaz', 'landing': '01:10 PM', 'avg': '13:10'},
  ];

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.date, style: AppTextStyles.h3),
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
            // Private notice banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.sub),
                  const SizedBox(width: 10),
                  Text(
                    'Private · only you can see this',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Table header
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
                  Expanded(flex: 3, child: Text('Land time', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                  Expanded(flex: 2, child: Text('Avg', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                ],
              ),
            ),

            // Table rows
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
                children: _pigeons.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.hair)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(p['name']!, style: AppTextStyles.bodyBold)),
                        Expanded(flex: 3, child: Text(p['landing']!, style: AppTextStyles.body)),
                        Expanded(flex: 2, child: Text(p['avg']!, textAlign: TextAlign.right, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Total Average Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(18),
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
                      Text('Total average', style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                      const SizedBox(height: 2),
                      Text('12:50', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    ],
                  ),
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                ],
              ),
            ),

            // Make live toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ok50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.ok, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Make live', style: AppTextStyles.bodyBold),
                  const Spacer(),
                  Switch.adaptive(
                    value: _isLive,
                    activeColor: AppColors.brand,
                    onChanged: (val) => setState(() => _isLive = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
