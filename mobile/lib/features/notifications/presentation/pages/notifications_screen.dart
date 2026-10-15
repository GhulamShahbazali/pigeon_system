import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/notifications_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsRepository _repo = sl<NotificationsRepository>();
  List<NotificationModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getFeed();
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _items = (res as dynamic).data as List<NotificationModel>;
      _loading = false;
    });
  }

  Future<void> _markAll() async {
    final res = await _repo.markAllRead();
    if (!mounted) return;
    if (res.isSuccess) _load();
  }

  Future<void> _markOne(NotificationModel n) async {
    if (n.isRead) return;
    final idx = _items.indexWhere((e) => e.id == n.id);
    if (idx != -1) {
      setState(() => _items[idx] = NotificationModel(
            id: n.id,
            type: n.type,
            entityType: n.entityType,
            entityId: n.entityId,
            isRead: true,
            actorCount: n.actorCount,
            createdAt: n.createdAt,
          ));
    }
    await _repo.markRead(n.id);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
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
        title: Text('Notifications', style: AppTextStyles.h2),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAll,
              child: Text('Mark all', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.mut),
            ),
            const SizedBox(height: 16),
            Text('No notifications yet', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Follow tournaments and people to see live updates here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.mut),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        itemBuilder: (context, i) => _tile(_items[i]),
      ),
    );
  }

  Widget _tile(NotificationModel n) {
    return InkWell(
      onTap: () => _markOne(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : AppColors.brand50.withValues(alpha: 0.35),
          border: const Border(bottom: BorderSide(color: AppColors.hair)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: n.iconBg, shape: BoxShape.circle),
              child: Icon(n.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: AppTextStyles.body.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(n.timeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
