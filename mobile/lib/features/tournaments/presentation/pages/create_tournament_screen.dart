import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class CreateTournamentScreen extends StatefulWidget {
  final bool isEditing;
  final String? initialTitle;
  final String? initialRules;
  final int? initialDays;
  final int? initialPigeons;
  final int? initialScheduleIndex;
  final String? initialFlyTime;
  final String? initialEndTime;
  final String? initialStartDate;
  final String? initialContact;

  const CreateTournamentScreen({
    super.key,
    this.isEditing = false,
    this.initialTitle,
    this.initialRules,
    this.initialDays,
    this.initialPigeons,
    this.initialScheduleIndex,
    this.initialFlyTime,
    this.initialEndTime,
    this.initialStartDate,
    this.initialContact,
  });

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  late int _days;
  late int _pigeons;
  late int _scheduleIndex; // 0 = Every day, 1 = Alternate days

  late final TextEditingController _titleController;
  late final TextEditingController _rulesController;
  late final TextEditingController _flyTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _startDateController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDays ?? 3;
    _pigeons = widget.initialPigeons ?? 20;
    _scheduleIndex = widget.initialScheduleIndex ?? 1;
    _titleController = TextEditingController(text: widget.initialTitle ?? 'City Loft Championship');
    _rulesController = TextEditingController(text: widget.initialRules ?? '');
    _flyTimeController = TextEditingController(text: widget.initialFlyTime ?? '06:00 AM');
    _endTimeController = TextEditingController(text: widget.initialEndTime ?? '06:00 PM');
    _startDateController = TextEditingController(text: widget.initialStartDate ?? '16 Oct 2026');
    _contactController = TextEditingController(text: widget.initialContact ?? '+92 300 1234567');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rulesController.dispose();
    _flyTimeController.dispose();
    _endTimeController.dispose();
    _startDateController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isFlyTime}) async {
    final initial = isFlyTime ? const TimeOfDay(hour: 6, minute: 0) : const TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';
      setState(() {
        if (isFlyTime) {
          _flyTimeController.text = formatted;
        } else {
          _endTimeController.text = formatted;
        }
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _startDateController.text = formatted;
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
        title: Text(widget.isEditing ? 'Edit Tournament' : 'New Tournament', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                widget.isEditing ? 'Save' : '1 / 2',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
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
                    // Cover picker
                    Text('Cover image · optional', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.duskMesh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add a cover photo', style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  'No photo? A gradient cover is used.',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: AppShadows.xs,
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.ink2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text('Title', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: AppTextStyles.bodyBold,
                      decoration: InputDecoration(
                        fillColor: AppColors.card,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rules
                    Text('Rules', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rulesController,
                      maxLines: 3,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Describe the tournament rules…',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                        fillColor: AppColors.card,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Steppers Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No. of days', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _StepperBox(
                                value: _days,
                                onDecrement: () => setState(() { if (_days > 1) _days--; }),
                                onIncrement: () => setState(() => _days++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pigeons', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _StepperBox(
                                value: _pigeons,
                                onDecrement: () => setState(() { if (_pigeons > 1) _pigeons--; }),
                                onIncrement: () => setState(() => _pigeons++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Schedule
                    Text('Schedule', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ScheduleTab(
                              title: 'Every day',
                              isSelected: _scheduleIndex == 0,
                              onTap: () => setState(() => _scheduleIndex = 0),
                            ),
                          ),
                          Expanded(
                            child: _ScheduleTab(
                              title: 'Alternate days',
                              isSelected: _scheduleIndex == 1,
                              onTap: () => setState(() => _scheduleIndex = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fly Time & End Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fly time', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _ReadOnlyPicker(
                                icon: Icons.access_time_rounded,
                                text: _flyTimeController.text,
                                onTap: () => _pickTime(isFlyTime: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ending time', style: AppTextStyles.labelUppercase),
                              const SizedBox(height: 8),
                              _ReadOnlyPicker(
                                icon: Icons.access_time_rounded,
                                text: _endTimeController.text,
                                onTap: () => _pickTime(isFlyTime: false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Start date
                    Text('Start date', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    _ReadOnlyPicker(
                      icon: Icons.calendar_today_rounded,
                      text: _startDateController.text,
                      onTap: _pickStartDate,
                    ),
                    const SizedBox(height: 20),

                    // Contact number
                    Text('Your contact number', style: AppTextStyles.labelUppercase),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactController,
                      style: AppTextStyles.bodyBold,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.brand, size: 20),
                        fillColor: AppColors.card,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Shown on the tournament — people reach you on WhatsApp or call.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mut),
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
                text: widget.isEditing ? 'Save Changes' : 'Next: Add participants',
                icon: widget.isEditing ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                isFullWidth: true,
                onPressed: () {
                  if (widget.isEditing) {
                    Navigator.of(context).pop();
                  } else {
                    context.push('/tournaments/participants');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperBox extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperBox({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text('$value', style: AppTextStyles.h4),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: AppColors.ink2),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleTab({
    required this.title,
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
