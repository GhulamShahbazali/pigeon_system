import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import 'message_requests_screen.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

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
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // TikTok rule: Message Requests Banner
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const MessageRequestsScreen()),
              );
            },
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Message requests', style: AppTextStyles.bodyBold),
                        const SizedBox(height: 2),
                        Text(
                          '2 people want to chat',
                          style: AppTextStyles.caption.copyWith(color: AppColors.sub),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.brand),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Conversation row 1 (Ahmed Loft - read tick)
          _ConversationTile(
            name: 'Ahmed Loft',
            initial: 'A',
            gradient: AppColors.avatarBlue,
            lastMessage: 'You: see you at the race!',
            time: '9:32',
            tickType: _TickType.read,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const ChatScreen(
                    contactName: 'Ahmed Loft',
                    isOnline: true,
                  ),
                ),
              );
            },
          ),

          // Conversation row 2 (Kashif Ali - unread badge)
          _ConversationTile(
            name: 'Kashif Ali',
            initial: 'K',
            gradient: AppColors.avatarPurple,
            lastMessage: '🎤 Voice message · 0:14',
            time: '8:10',
            unreadCount: 2,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const ChatScreen(
                    contactName: 'Kashif Ali',
                    isOnline: false,
                  ),
                ),
              );
            },
          ),

          // Conversation row 3 (Sohail Khan - delivered tick)
          _ConversationTile(
            name: 'Sohail Khan',
            initial: 'S',
            gradient: AppColors.avatarGold,
            lastMessage: 'You: nice birds 👍',
            time: 'Yest',
            tickType: _TickType.delivered,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const ChatScreen(
                    contactName: 'Sohail Khan',
                    isOnline: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _TickType { none, sent, delivered, read }

class _ConversationTile extends StatelessWidget {
  final String name;
  final String initial;
  final LinearGradient gradient;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final _TickType tickType;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.initial,
    required this.gradient,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.tickType = _TickType.none,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hair)),
        ),
        child: Row(
          children: [
            AppAvatar(text: initial, size: 44, gradient: gradient),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (tickType == _TickType.read) ...[
                        const Icon(Icons.done_all_rounded, size: 16, color: AppColors.brand),
                        const SizedBox(width: 4),
                      ] else if (tickType == _TickType.delivered) ...[
                        const Icon(Icons.done_all_rounded, size: 16, color: AppColors.mut),
                        const SizedBox(width: 4),
                      ] else if (tickType == _TickType.sent) ...[
                        const Icon(Icons.done_rounded, size: 16, color: AppColors.mut),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut, fontSize: 11)),
                const SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: AppTextStyles.captionBold.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
