import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/records_repository.dart';

/// A pigeon the user is drafting before the record is saved: just a name and a
/// landing time-of-day (the actual landing_time is this + the record's date).
class _DraftPigeon {
  String name;
  TimeOfDay landing;
  _DraftPigeon(this.name, this.landing);
}

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final RecordsRepository _repo = sl<RecordsRepository>();

  DateTime _date = DateTime.now();
  TimeOfDay _flyTime = const TimeOfDay(hour: 6, minute: 0);
  int _flownCount = 1;
  bool _isLive = true;
  bool _isSaving = false;

  final List<_DraftPigeon> _pigeons = [];

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String get _dateDisplay => '${_date.day} ${_months[_date.month - 1]}';
  String get _flyDisplay => _fmtTod(_flyTime);
  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _api24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _fmtTod(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:$m $p';
  }

  Future<void> _pickFlyTime() async {
    final picked = await showTimePicker(context: context, initialTime: _flyTime);
    if (picked != null) setState(() => _flyTime = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Bottom sheet to add or edit a pigeon (name + landing time). Returns the
  /// saved draft, or null if cancelled.
  Future<_DraftPigeon?> _openPigeonSheet({_DraftPigeon? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    TimeOfDay landing = existing?.landing ?? _flyTime;

    return showModalBottomSheet<_DraftPigeon>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(existing == null ? 'Add pigeon' : 'Edit pigeon',
                      textAlign: TextAlign.center, style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Text('Pigeon name', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyBold,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shaheen',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
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
                  const SizedBox(height: 16),
                  Text('Landing time', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: landing);
                      if (picked != null) setSheet(() => landing = picked);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.mut),
                          const SizedBox(width: 12),
                          Text(_fmtTod(landing), style: AppTextStyles.bodyBold),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.mut),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    text: existing == null ? 'Add pigeon' : 'Save pigeon',
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Enter the pigeon name')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(_DraftPigeon(name, landing));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addPigeon() async {
    final draft = await _openPigeonSheet();
    if (draft != null) {
      setState(() {
        _pigeons.add(draft);
        if (_pigeons.length > _flownCount) _flownCount = _pigeons.length;
      });
    }
  }

  Future<void> _editPigeon(int index) async {
    final draft = await _openPigeonSheet(existing: _pigeons[index]);
    if (draft != null) setState(() => _pigeons[index] = draft);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_pigeons.length > _flownCount) {
      _snack('Recorded pigeons cannot exceed total flown');
      return;
    }
    setState(() => _isSaving = true);

    // 1. Create the record (as private first; go-live afterwards if requested so
    //    the live machinery — auto-end, follower fan-out — runs server-side).
    final created = await _repo.createRecord(
      recordDate: _apiDate(_date),
      flyTime: _api24(_flyTime),
      totalPigeons: _flownCount,
      privacy: 'private',
    );
    if (!mounted) return;
    if (!created.isSuccess) {
      setState(() => _isSaving = false);
      _snack((created as dynamic).message ?? 'Could not save record');
      return;
    }
    final record = (created as dynamic).data as PersonalRecordModel;

    // 2. Add each returned pigeon with its landing instant.
    for (final p in _pigeons) {
      final landing =
          DateTime(_date.year, _date.month, _date.day, p.landing.hour, p.landing.minute);
      final r = await _repo.addPigeon(record.id, pigeonName: p.name, landingTime: landing);
      if (!mounted) return;
      if (!r.isSuccess) {
        setState(() => _isSaving = false);
        _snack((r as dynamic).message ?? 'Could not add ${p.name}');
        return;
      }
    }

    // 3. Broadcast it live if the toggle is on.
    if (_isLive) {
      final live = await _repo.goLive(record.id);
      if (!mounted) return;
      if (!live.isSuccess) {
        setState(() => _isSaving = false);
        _snack((live as dynamic).message ?? 'Saved, but could not go live');
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            onPressed: _isSaving ? null : _save,
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
                                text: _dateDisplay,
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
                                text: _flyDisplay,
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
                              // Never below the number of pigeons already recorded.
                              if (_flownCount > 1 && _flownCount > _pigeons.length) {
                                setState(() => _flownCount--);
                              }
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

                    if (_pigeons.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'No pigeons added yet — add each returned pigeon with its landing time.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                        ),
                      ),

                    // Pigeons items
                    ..._pigeons.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      return Dismissible(
                        key: ValueKey('${p.name}-$idx-${p.landing.hour}:${p.landing.minute}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => setState(() => _pigeons.removeAt(idx)),
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
                                    Text(p.name, style: AppTextStyles.bodyBold),
                                    Text('Landed ${_fmtTod(p.landing)}', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => _editPigeon(idx),
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

                    // Add pigeon button
                    InkWell(
                      onTap: _addPigeon,
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
                text: _isSaving
                    ? 'Saving…'
                    : (_isLive ? 'Go live & save' : 'Save record'),
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: _save,
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
