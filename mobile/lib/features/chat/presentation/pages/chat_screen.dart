import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../widgets/chat_options_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final bool isOnline;
  final bool isBlocked;

  const ChatScreen({
    super.key,
    required this.contactName,
    this.isOnline = true,
    this.isBlocked = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late bool _blocked;
  final _textController = TextEditingController();
  bool _showAttachBar = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': 'Salam! Ready for the race tomorrow? 🕊️',
      'time': '9:28',
      'type': 'text',
    },
    {
      'isMe': true,
      'text': 'Walaikum salam! Yes, kit is in great shape.',
      'time': '9:30',
      'tick': 'read',
      'type': 'text',
    },
    {
      'isMe': true,
      'duration': '0:12',
      'time': '9:31',
      'tick': 'delivered',
      'type': 'voice',
    },
    {
      'isMe': false,
      'caption': "Here's my loft this morning:",
      'time': '9:33',
      'type': 'image',
    },
    {
      'isMe': true,
      'duration': '0:45',
      'time': '9:34',
      'tick': 'read',
      'type': 'video',
    },
  ];

  @override
  void initState() {
    super.initState();
    _blocked = widget.isBlocked;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
              text: widget.contactName.isNotEmpty ? widget.contactName[0] : 'U',
              size: 36,
              gradient: AppColors.avatarBlue,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contactName, style: AppTextStyles.bodyBold),
                Text(
                  _blocked ? 'blocked' : (widget.isOnline ? 'online' : 'last seen 9:40'),
                  style: AppTextStyles.caption.copyWith(
                    color: _blocked ? AppColors.mut : (widget.isOnline ? AppColors.ok : AppColors.mut),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.ink2),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 22, color: AppColors.ink2),
            onPressed: () {
              ChatOptionsSheet.show(
                context,
                contactName: widget.contactName,
                onBlock: () => setState(() => _blocked = true),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  ..._messages.map((m) => _buildMessageBubble(m)),
                  if (_blocked) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warnBg,
                          border: Border.all(color: AppColors.warnBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_rounded, size: 14, color: AppColors.amberInk),
                            const SizedBox(width: 6),
                            Text(
                              'Single tick — messages not delivered',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.amberInk),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Blocked Banner or Input Bar
            if (_blocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('You blocked ${widget.contactName} · ', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger)),
                    GestureDetector(
                      onTap: () => setState(() => _blocked = false),
                      child: Text('Tap to unblock', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                    ),
                  ],
                ),
              )
            else ...[
              if (_showAttachBar) _buildAttachmentPanel(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showAttachBar ? Icons.close_rounded : Icons.add_circle_outline_rounded,
                        color: AppColors.brand,
                        size: 26,
                      ),
                      onPressed: () => setState(() => _showAttachBar = !_showAttachBar),
                    ),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: AppTextStyles.body,
                                decoration: InputDecoration(
                                  hintText: 'Message…',
                                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.mut),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.brandShadowColor, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          if (_textController.text.trim().isNotEmpty) {
                            setState(() {
                              _messages.add({
                                'isMe': true,
                                'text': _textController.text.trim(),
                                'time': '9:35',
                                'tick': _blocked ? 'sent' : 'delivered',
                                'type': 'text',
                              });
                              _textController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AttachOption(icon: Icons.camera_alt_rounded, label: 'Camera', color: AppColors.brand, bg: AppColors.brand50),
          _AttachOption(icon: Icons.image_rounded, label: 'Gallery', color: AppColors.purpleImage, bg: AppColors.purpleBg),
          _AttachOption(icon: Icons.videocam_rounded, label: 'Video', color: AppColors.pinkVideo, bg: AppColors.pinkBg),
          _AttachOption(icon: Icons.mic_rounded, label: 'Voice', color: AppColors.ok, bg: AppColors.ok50),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final type = msg['type'] as String;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: AppShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'text')
              Text(
                msg['text'] as String,
                style: AppTextStyles.body.copyWith(color: isMe ? Colors.white : AppColors.ink),
              )
            else if (type == 'voice')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.white28 : AppColors.brand50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: isMe ? Colors.white : AppColors.brand, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•••••••••••••••••',
                    style: TextStyle(color: isMe ? Colors.white : AppColors.mut, letterSpacing: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg['duration'] as String,
                    style: AppTextStyles.captionBold.copyWith(color: isMe ? AppColors.white90 : AppColors.mut),
                  ),
                ],
              )
            else if (type == 'image') ...[
              Text(msg['caption'] as String, style: AppTextStyles.body.copyWith(color: isMe ? Colors.white : AppColors.ink)),
              const SizedBox(height: 6),
              Container(
                height: 120,
                width: 180,
                decoration: BoxDecoration(
                  gradient: AppColors.heroMeshSky,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 36),
                ),
              ),
            ] else if (type == 'video') ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 180,
                    decoration: BoxDecoration(
                      gradient: AppColors.duskMesh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(msg['duration'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'] as String,
                  style: AppTextStyles.caption.copyWith(
                    color: isMe ? AppColors.white90 : AppColors.mut,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildTick(msg['tick'] as String?),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTick(String? tick) {
    if (tick == 'read') {
      return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.tickRead);
    } else if (tick == 'delivered') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
    } else {
      return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
    }
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.captionBold.copyWith(color: AppColors.ink2)),
      ],
    );
  }
}
