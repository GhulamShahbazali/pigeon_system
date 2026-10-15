import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/tournaments_repository.dart';
import '../widgets/tournament_contact_dialog.dart';
import '../widgets/tournament_share_dialog.dart';
import '../../data/record_exporter.dart';

class ParticipantDetailScreen extends StatefulWidget {
  final String? participantId;
  final String participantName;
  final int rank;
  final bool isOwner;
  final String? tournamentId;

  const ParticipantDetailScreen({
    super.key,
    this.participantId,
    required this.participantName,
    required this.rank,
    this.isOwner = false,
    this.tournamentId,
  });

  @override
  State<ParticipantDetailScreen> createState() => _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  final TournamentsRepository _repository = sl<TournamentsRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _participant;
  List<dynamic> _days = [];
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.tournamentId == null || widget.participantId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repository.getParticipantDetail(
      widget.tournamentId!,
      widget.participantId!,
    );

    if (!mounted) return;

    if (res.isFailure) {
      setState(() {
        _errorMessage = (res as dynamic).message ?? 'Failed to load details';
        _isLoading = false;
      });
      return;
    }

    final data = (res as dynamic).data as Map<String, dynamic>?;
    final participant = data?['participant'] as Map<String, dynamic>?;
    final days = (data?['days'] as List?) ?? [];

    final todayStr = _getTodayString();
    final todayIndex = days.indexWhere((d) => (d['date'] as String?)?.trim() == todayStr);

    setState(() {
      _participant = participant;
      _days = days;
      _isLoading = false;
      if (todayIndex != -1) {
        _selectedDay = todayIndex;
      }
    });
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isDayToday(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    return dateStr.trim() == _getTodayString();
  }

  bool _isDayPast(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    return dateStr.trim().compareTo(_getTodayString()) < 0;
  }

  bool _isDayFuture(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    return dateStr.trim().compareTo(_getTodayString()) > 0;
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null) return '0h 00m';
    final sec = (seconds as num).toInt();
    if (sec <= 0) return '0h 00m';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  ParticipantExportData _buildExportData(String name) {
    return ParticipantExportData(
      participantName: name,
      rank: widget.rank,
      overallAvgSeconds: (_participant?['overall_avg_seconds'] as num?)?.toInt(),
      overallReturnedCount: (_participant?['overall_returned_count'] as num?)?.toInt() ?? 0,
      days: _days.map((d) {
        final flights = ((d['flights'] as List?) ?? []).map((f) {
          final m = f as Map<String, dynamic>;
          return ExportFlight(
            pigeonName: m['pigeon_name']?.toString() ?? 'Pigeon',
            landingLabel: _formatLandingTime(m['landing_time']?.toString()),
            durationSeconds: (m['duration_seconds'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        return ExportDay(
          date: d['date']?.toString() ?? '',
          avgSeconds: (d['avg_seconds'] as num?)?.toInt(),
          returnedCount: (d['returned_count'] as num?)?.toInt() ?? 0,
          flights: flights,
        );
      }).toList(),
    );
  }

  String _formatLandingTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$min $period';
    } catch (_) {
      return iso;
    }
  }

  List<dynamic> _getCurrentFlights() {
    if (_days.isEmpty || _selectedDay >= _days.length) return [];
    return (_days[_selectedDay]['flights'] as List?) ?? [];
  }

  Future<void> _showPigeonDialog() async {
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tournament days scheduled.')),
      );
      return;
    }

    final activeDay = _days[_selectedDay < _days.length ? _selectedDay : 0];
    final dayId = activeDay['day_id'] ?? activeDay['id'];
    final dateStr = (activeDay['date'] as String?) ?? '';

    if (_isDayFuture(dateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upcoming day. Landings can only be recorded on $dateStr.')),
      );
      return;
    }
    if (_isDayPast(dateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day ended. New landings cannot be added, but existing ones can be edited or deleted.')),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: 'Pigeon ${_getCurrentFlights().length + 1}');
    TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
    String landingText = '12:30 PM';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Pigeon Landing', style: AppTextStyles.h4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pigeon Name / Tag', style: AppTextStyles.labelUppercase),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: AppTextStyles.bodyBold,
                decoration: InputDecoration(
                  hintText: 'e.g. Shaheen, 01, Blue Ring',
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
                    initialTime: pickedTime,
                  );
                  if (picked != null) {
                    pickedTime = picked;
                    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                    final minute = picked.minute.toString().padLeft(2, '0');
                    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                    setDialogState(() {
                      landingText = '${hour.toString().padLeft(2, '0')}:$minute $period';
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
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Text(landingText, style: AppTextStyles.bodyBold),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter pigeon name')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final dateParts = dateStr.split('-');
                      final year = int.parse(dateParts[0]);
                      final month = int.parse(dateParts[1]);
                      final day = int.parse(dateParts[2]);

                      final landingDateTime = DateTime(
                        year,
                        month,
                        day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      final res = await _repository.recordFlight(
                        widget.tournamentId!,
                        widget.participantId!,
                        {
                          'day_id': dayId,
                          'pigeon_name': name,
                          'landing_time': landingDateTime.toUtc().toIso8601String(),
                        },
                      );

                      if (ctx.mounted) Navigator.of(ctx).pop();

                      if (res.isSuccess) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Landing recorded successfully!')),
                          );
                          _loadData();
                        }
                      } else {
                        if (mounted) {
                          final err = (res as dynamic).message ?? 'Failed to record landing';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $err')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Add Landing', style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditFlightDialog(Map<String, dynamic> flight, Map<String, dynamic> activeDay) async {
    final flightId = flight['id']?.toString() ?? '';
    final currentName = (flight['pigeon_name'] as String?) ?? '';
    final currentLandingIso = (flight['landing_time'] as String?) ?? '';
    final dateStr = (activeDay['date'] as String?) ?? '';

    TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
    String landingText = '12:30 PM';
    if (currentLandingIso.isNotEmpty) {
      try {
        final dt = DateTime.parse(currentLandingIso).toLocal();
        pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final min = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        landingText = '${hour.toString().padLeft(2, '0')}:$min $period';
      } catch (_) {}
    }

    final nameCtrl = TextEditingController(text: currentName);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Pigeon Landing', style: AppTextStyles.h4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pigeon Name / Tag', style: AppTextStyles.labelUppercase),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: AppTextStyles.bodyBold,
                decoration: InputDecoration(
                  hintText: 'e.g. Shaheen, 01, Blue Ring',
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
                    initialTime: pickedTime,
                  );
                  if (picked != null) {
                    pickedTime = picked;
                    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                    final minute = picked.minute.toString().padLeft(2, '0');
                    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                    setDialogState(() {
                      landingText = '${hour.toString().padLeft(2, '0')}:$minute $period';
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
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Text(landingText, style: AppTextStyles.bodyBold),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter pigeon name')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      DateTime landingDateTime;
                      try {
                        final dateParts = dateStr.split('-');
                        final year = int.parse(dateParts[0]);
                        final month = int.parse(dateParts[1]);
                        final day = int.parse(dateParts[2]);
                        landingDateTime = DateTime(year, month, day, pickedTime.hour, pickedTime.minute);
                      } catch (_) {
                        final now = DateTime.now();
                        landingDateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
                      }

                      final res = await _repository.updateFlight(
                        widget.tournamentId!,
                        widget.participantId!,
                        flightId,
                        {
                          'pigeon_name': name,
                          'landing_time': landingDateTime.toUtc().toIso8601String(),
                        },
                      );

                      if (ctx.mounted) Navigator.of(ctx).pop();

                      if (res.isSuccess) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Landing updated successfully!')),
                          );
                          _loadData();
                        }
                      } else {
                        if (mounted) {
                          final err = (res as dynamic).message ?? 'Failed to update landing';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $err')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes', style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFlight(Map<String, dynamic> flight) async {
    final flightId = flight['id']?.toString() ?? '';
    final name = (flight['pigeon_name'] as String?) ?? 'this pigeon';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Landing?', style: AppTextStyles.h4),
        content: Text(
          'Are you sure you want to delete landing record for "$name"? The averages will be automatically recalculated.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.mut)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _repository.deleteFlight(
        widget.tournamentId!,
        widget.participantId!,
        flightId,
      );
      if (mounted) {
        if (res.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Landing record deleted.')),
          );
          _loadData();
        } else {
          final err = (res as dynamic).message ?? 'Failed to delete landing';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $err')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(widget.participantName, style: AppTextStyles.h3),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(widget.participantName, style: AppTextStyles.h3),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final pName = _participant?['name'] ?? widget.participantName;
    final pRank = _participant?['position'] ?? widget.rank;
    final currentFlights = _getCurrentFlights();
    final currentDay = _days.isNotEmpty && _selectedDay < _days.length ? _days[_selectedDay] : null;

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
        title: Text(pName, style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.ink2),
            onPressed: () {
              TournamentShareDialog.show(
                context,
                title: "Share $pName's record",
                subtitle: 'Day-by-day landings & averages · exported professionally',
                isParticipant: true,
                exportData: _buildExportData(pName),
              );
            },
          ),
          if (_participant?['phone'] != null || _participant?['contact_no'] != null)
            IconButton(
              icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.ink2),
              onPressed: () {
                final phone = _participant?['phone'] ?? _participant?['contact_no'];
                TournamentContactDialog.show(
                  context,
                  organizerName: pName,
                  phoneNumber: phone ?? '',
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
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
                      'You are organizer — you can record landings',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.amberInk),
                    ),
                  ],
                ),
              ),

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
                    child: Text('$pRank', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  AppAvatar(
                    name: pName.isNotEmpty ? pName : 'P',
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pName, style: AppTextStyles.bodyBold),
                        const SizedBox(height: 2),
                        Text(
                          'Rank #$pRank · ${_participant?['overall_returned_count'] ?? currentFlights.length} landed',
                          style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDuration(_participant?['overall_avg_seconds']),
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand),
                      ),
                      Text('overall', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // Day Tabs
            if (_days.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _days.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final d = entry.value;
                      final dStr = (d['date'] as String?) ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _DayTab(
                          dayLabel: 'DAY ${d['day_number']}',
                          dateLabel: dStr,
                          isSelected: _selectedDay == idx,
                          isToday: _isDayToday(dStr),
                          isPast: _isDayPast(dStr),
                          isFuture: _isDayFuture(dStr),
                          onTap: () => setState(() => _selectedDay = idx),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Date-Gated Owner Actions
            if (widget.isOwner && currentDay != null) ...[
              () {
                final dateStr = (currentDay['date'] as String?) ?? '';
                final isToday = _isDayToday(dateStr);
                final isPast = _isDayPast(dateStr);
                final isFuture = _isDayFuture(dateStr);

                if (isToday) {
                  return InkWell(
                    onTap: _showPigeonDialog,
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
                                Row(
                                  children: [
                                    Text('＋ Add pigeon / landing', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.brand,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'ACTIVE TODAY',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('name · landing time → duration auto', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
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
                  );
                } else if (isFuture) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.muted.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: AppColors.mut, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upcoming Day (Deactivated)',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.mut),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Flights will open for recording on $dateStr.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (isPast) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      border: Border.all(color: AppColors.warnBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_rounded, color: AppColors.amberInk, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day Ended — New Landings Closed',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.amberInk),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Existing landings can be edited or deleted below.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.amberInk),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }(),
            ],

            // Pigeons list: Table Header
            if (currentFlights.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                    Expanded(flex: 2, child: Text('Duration', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                    if (widget.isOwner) const SizedBox(width: 60),
                  ],
                ),
              ),
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
                  children: currentFlights.map((f) {
                    final flightMap = f is Map<String, dynamic> ? f : Map<String, dynamic>.from(f as Map);
                    final dateStr = (currentDay?['date'] as String?) ?? '';
                    final canModify = widget.isOwner && !_isDayFuture(dateStr);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.hair)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              (flightMap['pigeon_name'] as String?) ?? 'Pigeon',
                              style: AppTextStyles.bodyBold,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatLandingTime(flightMap['landing_time'] as String?),
                              style: AppTextStyles.body,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatDuration(flightMap['duration_seconds']),
                              textAlign: TextAlign.right,
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand),
                            ),
                          ),
                          if (canModify) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showEditFlightDialog(flightMap, currentDay!),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.soft,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: const Icon(Icons.edit_outlined, size: 15, color: AppColors.brand),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _confirmDeleteFlight(flightMap),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.danger50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.flight_land_rounded, size: 40, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text('No pigeons landed yet on Day ${_selectedDay + 1}', style: AppTextStyles.bodyBold),
                    const SizedBox(height: 4),
                    Text(
                      () {
                        final dateStr = (currentDay?['date'] as String?) ?? '';
                        if (_isDayFuture(dateStr)) {
                          return 'This day is in the future. Landings can only be entered on $dateStr.';
                        }
                        if (_isDayPast(dateStr)) {
                          return 'This day has ended without recorded landings.';
                        }
                        if (widget.isOwner) {
                          return 'Tap "Add pigeon / landing" above to record today\'s flight.';
                        }
                        return 'Flights will appear here as pigeons return.';
                      }(),
                      style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

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
                  Text(
                    _formatDuration(currentDay?['avg_seconds']),
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand),
                  ),
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
                      Text(
                        'Overall average · all days',
                        style: AppTextStyles.caption.copyWith(color: AppColors.white90, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(_participant?['overall_avg_seconds']),
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
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
  final bool isToday;
  final bool isPast;
  final bool isFuture;
  final VoidCallback onTap;

  const _DayTab({
    required this.dayLabel,
    required this.dateLabel,
    required this.isSelected,
    this.isToday = false,
    this.isPast = false,
    this.isFuture = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand
              : (isFuture ? AppColors.soft.withOpacity(0.6) : AppColors.card),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brand
                : (isToday ? AppColors.brand.withOpacity(0.6) : AppColors.line),
            width: isToday && !isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppShadows.sm : AppShadows.xs,
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFuture) ...[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: isSelected ? AppColors.white90 : AppColors.mut,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  dayLabel,
                  style: AppTextStyles.labelUppercase.copyWith(
                    color: isSelected ? AppColors.white90 : AppColors.mut,
                    fontSize: 10,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.brand,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppColors.brand : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isFuture ? AppColors.muted : AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
