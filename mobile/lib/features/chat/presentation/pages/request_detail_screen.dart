import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/chat_repository.dart';

/// A single pending message request. Pops `true` when accepted, `false` when
/// declined, so the requests list can refresh.
class RequestDetailScreen extends StatefulWidget {
  final String conversationId;
  final String senderName;
  final String? senderPhotoUrl;
  final String messageContent;

  const RequestDetailScreen({
    super.key,
    required this.conversationId,
    required this.senderName,
    this.senderPhotoUrl,
    this.messageContent = '',
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final ChatRepository _repo = sl<ChatRepository>();
  bool _busy = false;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await _repo.acceptRequest(widget.conversationId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      _snack((res as dynamic).message ?? 'Could not accept the request');
    }
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await _repo.declineRequest(widget.conversationId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.isSuccess) {
      Navigator.of(context).pop(false);
    } else {
      _snack((res as dynamic).message ?? 'Could not delete the request');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            AppAvatar(
              name: widget.senderName,
              imageUrl: widget.senderPhotoUrl,
              size: 34,
              gradient: AppColors.avatarGreen,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.senderName, style: AppTextStyles.bodyBold),
                Text('Message request',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                children: [
                  if (widget.messageContent.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                            bottomLeft: Radius.circular(4),
                          ),
                          boxShadow: AppShadows.xs,
                        ),
                        child: Text(widget.messageContent,
                            style: AppTextStyles.body.copyWith(color: AppColors.ink)),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        border: Border.all(color: AppColors.brand100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'They can send more only after you accept',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.brand),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  AppButton(
                    text: 'Accept',
                    isFullWidth: true,
                    isLoading: _busy,
                    onPressed: _accept,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Delete request',
                    icon: Icons.delete_outline_rounded,
                    variant: AppButtonVariant.soft,
                    isFullWidth: true,
                    onPressed: _decline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
