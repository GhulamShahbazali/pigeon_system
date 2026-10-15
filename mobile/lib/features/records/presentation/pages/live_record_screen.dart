import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/records_repository.dart';

class LiveRecordScreen extends StatefulWidget {
  final String? recordId;
  final bool isOwner;
  final String? loftName;

  const LiveRecordScreen({
    super.key,
    this.recordId,
    this.isOwner = false,
    this.loftName,
  });

  @override
  State<LiveRecordScreen> createState() => _LiveRecordScreenState();
}

class _LiveRecordScreenState extends State<LiveRecordScreen> {
  final RecordsRepository _recordsRepository = sl<RecordsRepository>();

  RecordDetailModel? _record;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.isOwner;
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? targetId = widget.recordId;

    if (targetId == null || targetId.isEmpty) {
      final liveListResult = await _recordsRepository.getLiveNow();
      if (!mounted) return;
      final liveList = liveListResult.dataOrNull;
      if (liveList != null && liveList.isNotEmpty) {
        targetId = liveList.first.id;
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No live record found.';
        });
        return;
      }
    }

    final result = await _recordsRepository.getRecordDetail(targetId);
    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _record = data;
          _isLiked = data.isLiked;
          _likeCount = data.likeCount;
          _isOwner = data.isOwner || widget.isOwner;
          _isLoading = false;
        });
      },
      failure: (message, code) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _toggleLike() async {
    if (_record == null) return;
    final newLiked = !_isLiked;
    setState(() {
      _isLiked = newLiked;
      _likeCount += newLiked ? 1 : -1;
    });

    final res = await _recordsRepository.toggleLike(_record!.id, newLiked);
    if (!res.isSuccess && mounted) {
      // Revert if failed
      setState(() {
        _isLiked = !newLiked;
        _likeCount += !newLiked ? 1 : -1;
      });
    }
  }

  Future<void> _showAddLandingSheet() async {
    if (_record == null) return;
    final nameController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Add Pigeon Landing', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Pigeon Name / Tag',
                        hintText: 'e.g. Shaheen, 402',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Landing Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final now = DateTime.now();
                        final landingDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        Navigator.of(ctx).pop();
                        final res = await _recordsRepository.addPigeon(
                          _record!.id,
                          pigeonName: name,
                          landingTime: landingDateTime,
                        );
                        if (!mounted) return;
                        res.when(
                          success: (_) => _loadRecord(),
                          failure: (message, _) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        );
                      },
                      child: const Text('Record Landing', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _endLive() async {
    if (_record == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Live Record?'),
        content: const Text('This will complete your live flight record and save it to your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End & Save'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _recordsRepository.endRecord(_record!.id);
      if (!mounted) return;
      res.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live record ended and saved to history.')),
          );
          Navigator.of(context).pop();
        },
        failure: (message, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(widget.loftName ?? 'Live Record', style: AppTextStyles.h4),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    if (_errorMessage != null || _record == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(widget.loftName ?? 'Live Record', style: AppTextStyles.h4),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.mut),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Record not found', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final record = _record!;
    final loftTitle = record.owner?.displayName != null
        ? "${record.owner!.displayName}'s loft"
        : (widget.loftName ?? "Live Flight");

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
        title: Column(
          children: [
            Text(loftTitle, style: AppTextStyles.h4),
            Text('Date: ${record.recordDate} · Fly: ${record.formattedFlyTime}',
                style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!_isOwner)
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? AppColors.danger : AppColors.ink2,
              ),
              onPressed: _toggleLike,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _loadRecord,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Status bar
                      if (_isOwner)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0E3A26), Color(0xFF12B76A)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("You're live", style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
                                    Text('${record.viewCount} viewers · ${record.returnedCount} landed',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: _endLive,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.white28,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.stop_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text('End', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: AppColors.ok50,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.ok,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE · updating now',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.ok),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Content: Table for watcher vs Owner edit list
                      if (!_isOwner) ...[
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
                              Expanded(flex: 3, child: Text('Landed', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                              Expanded(flex: 2, child: Text('Duration', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
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
                          child: record.pigeons.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  child: Center(
                                    child: Text(
                                      'No pigeons have landed yet.',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: record.pigeons.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppColors.hair)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(p.pigeonName, style: AppTextStyles.bodyBold)),
                                          Expanded(flex: 3, child: Text(p.formattedLandingTime, style: AppTextStyles.body)),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              p.formattedDuration,
                                              textAlign: TextAlign.right,
                                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ] else ...[
                        // Owner live edit rows
                        if (record.pigeons.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                            child: Text(
                              'No landings recorded yet. Tap "Add landing" when a pigeon returns.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...record.pigeons.map((p) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.pigeonName, style: AppTextStyles.bodyBold),
                                        Text(
                                          'Landed ${p.formattedLandingTime}',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    p.formattedDuration,
                                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand),
                                  ),
                                ],
                              ),
                            );
                          }),
                        // Add landing button
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: AppButton(
                            text: 'Add landing',
                            icon: Icons.add,
                            variant: AppButtonVariant.soft,
                            isFullWidth: true,
                            onPressed: _showAddLandingSheet,
                          ),
                        ),
                      ],

                      // Total average card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                                Text('Total average · ${record.returnedCount} of ${record.totalPigeons} landed',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                                const SizedBox(height: 2),
                                Text(record.formattedAverage, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                              ],
                            ),
                            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                          ],
                        ),
                      ),

                      // Viewer stats engagement row
                      if (!_isOwner)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 18),
                                  const SizedBox(width: 6),
                                  Text('$_likeCount', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, color: AppColors.mut, size: 18),
                                  const SizedBox(width: 6),
                                  Text('${record.viewCount}', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.emoji_events_outlined, color: AppColors.mut, size: 18),
                                  const SizedBox(width: 6),
                                  Text('${record.totalPigeons} flown', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isOwner)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: AppButton(
                  text: 'End live & save',
                  icon: Icons.stop_rounded,
                  variant: AppButtonVariant.dark,
                  isFullWidth: true,
                  onPressed: _endLive,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
