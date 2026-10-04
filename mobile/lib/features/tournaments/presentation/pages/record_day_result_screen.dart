import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class RecordDayResultScreen extends StatefulWidget {
  final int dayNumber;
  final String date;

  const RecordDayResultScreen({
    super.key,
    this.dayNumber = 2,
    this.date = '18 Oct',
  });

  @override
  State<RecordDayResultScreen> createState() => _RecordDayResultScreenState();
}

class _RecordDayResultScreenState extends State<RecordDayResultScreen> {
  final List<Map<String, String>> _rows = [
    {'participant': 'Bilal Raza', 'pigeon': 'Shaheen', 'landing': '12:40 PM'},
    {'participant': 'Kashif Ali', 'pigeon': 'Toofan', 'landing': ''},
    {'participant': 'Usman Tariq', 'pigeon': 'Noori', 'landing': ''},
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
        title: Text('Record — Day ${widget.dayNumber}', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Save', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      border: Border.all(color: AppColors.warnBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.amberInk),
                            const SizedBox(width: 8),
                            Text(
                              'Fly 06:00 AM · ${widget.date}',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.amberInk),
                            ),
                          ],
                        ),
                        Text('20 pigeons', style: AppTextStyles.captionBold.copyWith(color: AppColors.amberInk)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._rows.map((item) {
                    final hasLanding = item['landing']!.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['participant']} · ${item['pigeon']}',
                            style: AppTextStyles.labelUppercase,
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 13, minute: 0),
                              );
                              if (picked != null) {
                                final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                final minute = picked.minute.toString().padLeft(2, '0');
                                final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                setState(() {
                                  item['landing'] = '${hour.toString().padLeft(2, '0')}:$minute $period';
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                border: Border.all(
                                  color: hasLanding ? AppColors.brand : AppColors.line,
                                  width: hasLanding ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppShadows.xs,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: hasLanding ? AppColors.brand : AppColors.mut,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    hasLanding ? item['landing']! : 'Tap to set landing time',
                                    style: hasLanding
                                        ? AppTextStyles.bodyBold
                                        : AppTextStyles.body.copyWith(color: AppColors.mut),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: 'Save day ${widget.dayNumber} results',
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
