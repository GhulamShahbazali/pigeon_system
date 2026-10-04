import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../widgets/tournament_contact_dialog.dart';
import '../widgets/tournament_share_dialog.dart';

class ParticipantDetailScreen extends StatefulWidget {
  final String participantName;
  final int rank;
  final bool isOwner;

  const ParticipantDetailScreen({
    super.key,
    required this.participantName,
    required this.rank,
    this.isOwner = false,
  });

  @override
  State<ParticipantDetailScreen> createState() => _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  int _selectedDay = 0;
  final List<Map<String, String>> _pigeons = [
    {'name': 'Shaheen', 'landing': '12:40 PM', 'avg': '12:40'},
    {'name': 'Toofan', 'landing': '01:05 PM', 'avg': '13:05'},
    {'name': 'Noori', 'landing': '01:20 PM', 'avg': '13:20'},
  ];

  Future<void> _showPigeonDialog({int? editIndex}) async {
    final isEditing = editIndex != null;
    final initial = isEditing ? _pigeons[editIndex] : null;
    final nameCtrl = TextEditingController(text: initial?['name'] ?? '');
    final landingCtrl = TextEditingController(text: initial?['landing'] ?? '12:40 PM');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Pigeon' : 'Add Pigeon / Landing', style: AppTextStyles.h4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pigeon Name', style: AppTextStyles.labelUppercase),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: AppTextStyles.bodyBold,
                decoration: InputDecoration(
                  hintText: 'e.g. Shaheen',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: AppColors.soft,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Text('Landing Time', style: AppTextStyles.labelUppercase),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 40),
                  );
                  if (picked != null) {
                    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                    final minute = picked.minute.toString().padLeft(2, '0');
                    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                    setDialogState(() {
                      landingCtrl.text = '${hour.toString().padLeft(2, '0')}:$minute $period';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Text(landingCtrl.text, style: AppTextStyles.bodyBold),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.mut)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? 'Pigeon' : nameCtrl.text.trim();
                final landing = landingCtrl.text;
                // auto avg display from landing time
                final avg = landing.split(' ').first;
                setState(() {
                  if (isEditing) {
                    _pigeons[editIndex] = {'name': name, 'landing': landing, 'avg': avg};
                  } else {
                    _pigeons.add({'name': name, 'landing': landing, 'avg': avg});
                  }
                });
                Navigator.of(ctx).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add', style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.participantName, style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Save', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.ink2),
              onPressed: () {
                TournamentShareDialog.show(
                  context,
                  title: "Share ${widget.participantName}'s record",
                  subtitle: 'Day-by-day landings & averages · exported professionally',
                  isParticipant: true,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.ink2),
              onPressed: () {
                TournamentContactDialog.show(
                  context,
                  organizerName: widget.participantName,
                  phoneNumber: '+92 300 1234567',
                );
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Owner Warning Banner if owner
            if (widget.isOwner)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  border: Border.all(color: AppColors.warnBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 16, color: AppColors.amberInk),
                    const SizedBox(width: 8),
                    Text(
                      'You created this — only you can edit',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.amberInk),
                    ),
                  ],
                ),
              )
            else
              // Rank Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppShadows.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${widget.rank}', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    AppAvatar(
                      text: widget.participantName.isNotEmpty ? widget.participantName[0] : 'P',
                      size: 40,
                      gradient: AppColors.avatarBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.participantName, style: AppTextStyles.bodyBold),
                          const SizedBox(height: 2),
                          Text('Rank #${widget.rank} · ${_pigeons.length} pigeons', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('13:10', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                        Text('overall', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

            // Day Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _DayTab(
                      dayLabel: 'DAY 1',
                      dateLabel: '16 Oct',
                      isSelected: _selectedDay == 0,
                      onTap: () => setState(() => _selectedDay = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DayTab(
                      dayLabel: 'DAY 2',
                      dateLabel: '18 Oct',
                      isSelected: _selectedDay == 1,
                      onTap: () => setState(() => _selectedDay = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DayTab(
                      dayLabel: 'DAY 3',
                      dateLabel: '20 Oct',
                      isSelected: _selectedDay == 2,
                      onTap: () => setState(() => _selectedDay = 2),
                    ),
                  ),
                ],
              ),
            ),

            // Pigeons list: Viewer table VS Owner editable list
            if (!widget.isOwner) ...[
              // Table Header
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
                    Expanded(flex: 3, child: Text('Landing', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                    Expanded(flex: 2, child: Text('Avg', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                  ],
                ),
              ),
              // Table Rows
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
            ] else ...[
              // Owner edit list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Day ${_selectedDay + 1} · pigeons', style: AppTextStyles.labelUppercase),
                    Text('tap to edit', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ..._pigeons.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
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
                        onTap: () => _showPigeonDialog(editIndex: idx),
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
                );
              }),
              // Add pigeon row
              InkWell(
                onTap: () => _showPigeonDialog(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    border: Border.all(color: AppColors.brand100),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('＋ Add pigeon / landing', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                            Text('name · landing time → avg auto', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Day subtotal average
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day ${_selectedDay + 1} total average', style: AppTextStyles.bodyBold),
                  Text('13:01', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                ],
              ),
            ),

            // Overall Total Average Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                      Text('Overall average · all days', style: AppTextStyles.caption.copyWith(color: AppColors.white90, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('13:10', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    ],
                  ),
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
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

class _DayTab extends StatelessWidget {
  final String dayLabel;
  final String dateLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayTab({
    required this.dayLabel,
    required this.dateLabel,
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
          color: isSelected ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.brand : AppColors.line),
          boxShadow: isSelected ? AppShadows.sm : AppShadows.xs,
        ),
        child: Column(
          children: [
            Text(
              dayLabel,
              style: AppTextStyles.labelUppercase.copyWith(
                color: isSelected ? AppColors.white90 : AppColors.mut,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
