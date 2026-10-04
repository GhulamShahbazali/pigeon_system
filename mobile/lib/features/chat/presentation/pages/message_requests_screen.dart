import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import 'request_detail_screen.dart';

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = [
      {
        'name': 'Usman Tariq',
        'initial': 'U',
        'grad': AppColors.avatarGreen,
        'msg': 'Assalam o alaikum, loved your loft!',
      },
      {
        'name': 'Rashid Lofts',
        'initial': 'R',
        'grad': AppColors.avatarBlue,
        'msg': 'Are you joining the Valley Cup?',
      },
    ];

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
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'People who messaged you first. Accept to start chatting — they can only send more once you do.',
              style: AppTextStyles.body.copyWith(color: AppColors.sub, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          ...requests.map((req) {
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => RequestDetailScreen(
                      senderName: req['name'] as String,
                      senderInitial: req['initial'] as String,
                      messageContent: 'Assalam o alaikum! Loved your loft — the young Shaheen is brilliant. 🕊️',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.hair)),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      text: req['initial'] as String,
                      size: 44,
                      gradient: req['grad'] as LinearGradient,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['name'] as String, style: AppTextStyles.bodyBold),
                          const SizedBox(height: 3),
                          Text(
                            req['msg'] as String,
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
