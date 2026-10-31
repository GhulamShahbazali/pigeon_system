import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import 'request_detail_screen.dart';

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  final ChatRepository _repo = sl<ChatRepository>();
  List<ConversationModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getRequests();
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _requests = (res as dynamic).data as List<ConversationModel>;
      _loading = false;
    });
  }

  Future<void> _openRequest(ConversationModel req) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => RequestDetailScreen(
          conversationId: req.id,
          senderName: req.otherName,
          senderPhotoUrl: req.otherPhotoUrl,
          messageContent: req.lastMessagePreview ?? '',
        ),
      ),
    );
    // Accepted (true) or declined (false) → the request is gone; refresh.
    if (result != null && mounted) _load();
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
        title: Text('Requests', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_unread_outlined, size: 34, color: AppColors.mut),
            ),
            const SizedBox(height: 14),
            Text('No message requests', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text('When someone messages you first, it shows up here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.mut)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'People who messaged you first. Accept to start chatting — they can only send more once you do.',
              style: AppTextStyles.body.copyWith(color: AppColors.sub, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 6),
          ..._requests.map((req) {
            return InkWell(
              onTap: () => _openRequest(req),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.hair)),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: req.otherName,
                      imageUrl: req.otherPhotoUrl,
                      size: 44,
                      gradient: AppColors.avatarGreen,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.otherName, style: AppTextStyles.bodyBold),
                          const SizedBox(height: 3),
                          Text(
                            req.lastMessagePreview ?? 'Sent you a message request',
                            style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mut),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
