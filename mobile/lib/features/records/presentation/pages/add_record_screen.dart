import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/edit_pigeon_sheet.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  int _flownCount = 18;
  bool _isLive = true;
  String _dateText = '16 Oct';
  String _flyTimeText = '06:00 AM';

  final List<Map<String, String>> _pigeons = [
    {'name': 'Shaheen', 'landing': '12:40 PM', 'avg': '12:40'},
    {'name': 'Toofan', 'landing': '01:05 PM', 'avg': '13:05'},
    {'name': 'Noori', 'landing': '01:20 PM', 'avg': '13:20'},
  ];

  Future<void> _pickFlyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _flyTimeText = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      setState(() {
        _dateText = '${picked.day} ${months[picked.month - 1]}';
      });
    }
  }

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
        title: Text('New Day Record', style: AppTextStyles.h3),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Fly time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _ReadOnlyPicker(
                                icon: Icons.calendar_today_rounded,
                                text: _dateText,
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fly time', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _ReadOnlyPicker(
                                icon: Icons.access_time_rounded,
                                text: _flyTimeText,
                                onTap: _pickFlyTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total pigeons flown stepper
                    Text('Total pigeons flown', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18, color: AppColors.ink2),
                            onPressed: () {
                              if (_flownCount > 1) setState(() => _flownCount--);
                            },
                          ),
                          Text('$_flownCount', style: AppTextStyles.h4),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18, color: AppColors.ink2),
                            onPressed: () => setState(() => _flownCount++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pigeons section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pigeons (${_pigeons.length})', style: AppTextStyles.labelUppercase),
                        Text('tap to edit · swipe to delete', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Pigeons items
                    ..._pigeons.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      return Dismissible(
                        key: ValueKey(p['name']! + idx.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() => _pigeons.removeAt(idx));
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text('Delete', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['name']!, style: AppTextStyles.bodyBold),
                                    Text('Landed ${p['landing']}', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                                  ],
                                ),
                              ),
                              Text(p['avg']!, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  EditPigeonSheet.show(
                                    context,
                                    pigeonName: p['name']!,
                                    landingTime: p['landing']!,
                                    average: p['avg']!,
                                    onSave: (newName, newLanding) {
                                      setState(() {
                                        _pigeons[idx] = {'name': newName, 'landing': newLanding, 'avg': newLanding.split(' ')[0]};
                                      });
                                    },
                                    onDelete: () => setState(() => _pigeons.removeAt(idx)),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _pigeons.removeAt(idx)),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: AppColors.danger50, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),

                    // Add pigeon dashed button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _pigeons.add({
                            'name': 'Baaz ${_pigeons.length + 1}',
                            'landing': '01:30 PM',
                            'avg': '13:30',
                          });
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.brand100, style: BorderStyle.solid),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 18, color: AppColors.brand),
                            const SizedBox(width: 8),
                            Text('Add pigeon', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Make this live toggle row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(14),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Make this live', style: AppTextStyles.bodyBold),
                                Text(
                                  'Followers see it in "Live now" + get notified',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isLive,
                            activeColor: AppColors.brand,
                            onChanged: (val) => setState(() => _isLive = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: _isLive ? 'Go live & save' : 'Save record',
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

class _ReadOnlyPicker extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _ReadOnlyPicker({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mut),
            const SizedBox(width: 10),
            Text(text, style: AppTextStyles.bodyBold),
          ],
        ),
      ),
    );
  }
}
