import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/records_repository.dart';
import 'live_record_screen.dart';

/// The signed-in user's own records (private + live), from GET /me/records.
class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key});

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  final RecordsRepository _repo = sl<RecordsRepository>();
  List<PersonalRecordModel> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getMyRecords();
    if (!mounted) return;
    res.when(
      success: (data) => setState(() {
        _records = data;
        _loading = false;
      }),
      failure: (m, __) => setState(() {
        _error = m;
        _loading = false;
      }),
    );
  }

  Future<void> _createRecord() async {
    await context.push('/records/create');
    if (mounted) _load(); // show the newly created record on return
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(s.myRecords, style: AppTextStyles.screenTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: _createRecord,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.newRecord, style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _buildBody(s),
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body)));
    }
    if (_records.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.format_list_bulleted_rounded, size: 54, color: AppColors.muted),
        const SizedBox(height: 12),
        Center(child: Text(s.noRecordsYet, style: AppTextStyles.cardTitle)),
        const SizedBox(height: 6),
        Center(child: Text(s.addRecordHint, style: AppTextStyles.caption)),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _createRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(s.addFirstRecord,
                style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
          ),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _records.length,
      itemBuilder: (context, i) => _recordCard(_records[i], s),
    );
  }

  Widget _recordCard(PersonalRecordModel r, AppStrings s) {
    final isLive = r.isLive;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LiveRecordScreen(recordId: r.id, isOwner: true, loftName: 'My Record'),
          ));
        },
        title: Row(
          children: [
            Text(r.recordDate, style: AppTextStyles.bodyBold),
            const SizedBox(width: 8),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.ok50, borderRadius: BorderRadius.circular(20)),
                child: Text(s.live, style: AppTextStyles.captionBold.copyWith(color: AppColors.ok, fontSize: 10)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
                child: Text(r.privacy == 'live' ? s.ended : s.privateLabel,
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.mut, fontSize: 10)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Fly ${r.formattedFlyTime} · ${r.returnedCount} of ${r.totalPigeons} landed · avg ${r.formattedAverage}',
            style: AppTextStyles.caption.copyWith(color: AppColors.sub),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mut),
      ),
    );
  }
}
