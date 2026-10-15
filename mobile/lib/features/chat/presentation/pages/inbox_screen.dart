import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import 'message_requests_screen.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatRepository _repo = sl<ChatRepository>();
  List<ConversationModel> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getInbox();
    if (!mounted) return;
    res.when(
      success: (data) => setState(() {
        _conversations = data;
        _loading = false;
      }),
      failure: (m, __) => setState(() {
        _error = m;
        _loading = false;
      }),
    );
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
        title: Text('Messages', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22, color: AppColors.ink),
            onPressed: () => context.push('/messages/search'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Message requests entry
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const MessageRequestsScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              border: Border.all(color: AppColors.brand100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Message requests', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 2),
                      Text('People who want to chat',
                          style: AppTextStyles.caption.copyWith(color: AppColors.sub)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.brand),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center)),
          )
        else if (_conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            child: Column(
              children: [
                const Icon(Icons.forum_outlined, size: 54, color: AppColors.muted),
                const SizedBox(height: 12),
                Text('No conversations yet', style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Start a chat from someone’s profile.',
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ..._conversations.map(_buildTile),
      ],
    );
  }

  Widget _buildTile(ConversationModel c) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (ctx) => ChatScreen(
                conversationId: c.id,
                otherUserId: c.otherUserId,
                contactName: c.otherName,
                contactPhotoUrl: c.otherPhotoUrl,
              ),
            ))
            .then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hair))),
        child: Row(
          children: [
            AppAvatar(text: c.otherName, imageUrl: c.otherPhotoUrl, size: 44, gradient: AppColors.avatarBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.otherName, style: AppTextStyles.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    c.lastMessagePreview?.isNotEmpty == true ? c.lastMessagePreview! : 'Tap to open chat',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (c.timeLabel.isNotEmpty)
              Text(c.timeLabel, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
