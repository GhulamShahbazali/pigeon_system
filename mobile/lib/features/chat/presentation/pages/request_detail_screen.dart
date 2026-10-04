import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import 'chat_screen.dart';

class RequestDetailScreen extends StatelessWidget {
  final String senderName;
  final String senderInitial;
  final String messageContent;

  const RequestDetailScreen({
    super.key,
    this.senderName = 'Usman Tariq',
    this.senderInitial = 'U',
    this.messageContent = 'Assalam o alaikum! Loved your loft — the young Shaheen is brilliant. 🕊️',
  });

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
              text: senderInitial,
              size: 34,
              gradient: AppColors.avatarGreen,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(senderName, style: AppTextStyles.bodyBold),
                Text('Message request', style: AppTextStyles.caption.copyWith(color: AppColors.mut, fontSize: 11)),
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
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Today', style: AppTextStyles.captionBold.copyWith(color: AppColors.sub, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Incoming Bubble
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
                      child: Text(
                        messageContent,
                        style: AppTextStyles.body.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // TikTok warning pill
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
            // Bottom Action Bar: Accept, Delete, Block
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  AppButton(
                    text: 'Accept & reply',
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            contactName: senderName,
                            isOnline: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          variant: AppButtonVariant.soft,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Block',
                          icon: Icons.block_flipped,
                          variant: AppButtonVariant.danger,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
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
