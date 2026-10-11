import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _myChats = [
    {
      'name': 'Bilal Racing',
      'initial': 'B',
      'gradient': AppColors.avatarBlue,
      'lastMsg': 'You: see you at the race!',
      'time': '9:32',
      'isRead': true,
    },
    {
      'name': 'Bilqees Loft',
      'initial': 'B',
      'gradient': AppColors.avatarPurple,
      'lastMsg': '🎤 Voice message · 0:14',
      'time': 'Yest',
      'isRead': false,
    },
    {
      'name': 'Ahmed Loft',
      'initial': 'A',
      'gradient': AppColors.avatarGreen,
      'lastMsg': 'Are the birds returning today?',
      'time': 'Yesterday',
      'isRead': true,
    },
  ];

  final List<Map<String, dynamic>> _startNewChatUsers = [
    {
      'name': 'Bilawal Khan',
      'handle': '@bilawal.k',
      'initial': 'B',
      'gradient': AppColors.avatarGold,
      'info': 'not in your chats',
    },
    {
      'name': 'Baber Pigeons',
      'handle': '@baber_p',
      'initial': 'B',
      'gradient': AppColors.avatarBlue,
      'info': 'not in your chats',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filteredChats = _myChats.where((item) {
      if (query.isEmpty) return true;
      return (item['name'] as String).toLowerCase().contains(query) ||
          (item['lastMsg'] as String).toLowerCase().contains(query);
    }).toList();

    final filteredNewUsers = _startNewChatUsers.where((item) {
      if (query.isEmpty) return true;
      return (item['name'] as String).toLowerCase().contains(query) ||
          (item['handle'] as String).toLowerCase().contains(query);
    }).toList();

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
        title: Text('Search chats', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Search Input matching wireframe 1b (.search.on)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchController.text.isNotEmpty ? AppColors.brand : AppColors.line,
                  width: _searchController.text.isNotEmpty ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyBold,
                      decoration: InputDecoration(
                        hintText: 'Search chats or start a new one…',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.mut,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 1: Your conversations
            if (filteredChats.isNotEmpty) ...[
              Text(
                'Your conversations',
                style: AppTextStyles.labelUppercase,
              ),
              const SizedBox(height: 8),
              ...filteredChats.map((chat) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => context.push('/messages/chat/${Uri.encodeComponent(chat['name'])}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadows.xs,
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            text: chat['initial'] as String,
                            size: 44,
                            gradient: chat['gradient'] as LinearGradient,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(chat['name'] as String, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (chat['isRead'] == true) ...[
                                      const Icon(Icons.done_all_rounded, size: 16, color: AppColors.brand),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        chat['lastMsg'] as String,
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
                          Text(
                            chat['time'] as String,
                            style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            // Section 2: Start a new chat
            if (filteredNewUsers.isNotEmpty) ...[
              Text(
                'Start a new chat',
                style: AppTextStyles.labelUppercase,
              ),
              const SizedBox(height: 8),
              ...filteredNewUsers.map((user) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => context.push('/messages/chat/${Uri.encodeComponent(user['name'])}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadows.xs,
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            text: user['initial'] as String,
                            size: 44,
                            gradient: user['gradient'] as LinearGradient,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] as String, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 3),
                                Text(
                                  '${user['handle']} · ${user['info']}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.brand50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.brand,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
