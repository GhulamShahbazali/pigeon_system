import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/local_storage/secure_storage_service.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/image_picker_helper.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../../../core/result/result.dart';
import '../widgets/voice_bubble.dart';
import 'video_player_screen.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String? conversationId;
  final String? otherUserId;
  final String? contactPhotoUrl;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.contactName,
    this.conversationId,
    this.otherUserId,
    this.contactPhotoUrl,
    this.isOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _repo = sl<ChatRepository>();
  final SocketService _socket = sl<SocketService>();
  final SecureStorageService _storage = sl<SecureStorageService>();

  final _textController = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();

  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _hasText = false;
  bool _showAttachBar = false;

  String? _myId;
  String? _conversationId;

  // WhatsApp-style receipts: the other side's read/delivered message ids.
  String? _otherReadId;
  String? _otherDeliveredId;

  // Voice recording state
  bool _isRecording = false;
  String? _recordPath;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _myId = await _storage.getUserId();
    // Opened by user id only (e.g. from a profile)? Resolve any existing
    // conversation with that user so messages sent earlier reload on reopen,
    // instead of showing an empty "Say salam" every time.
    if (_conversationId == null && widget.otherUserId != null) {
      final res = await _repo.findConversationWith(widget.otherUserId!);
      if (mounted && res.isSuccess) {
        final cid = (res as dynamic).data as String?;
        if (cid != null && cid.isNotEmpty) _conversationId = cid;
      }
    }
    if (_conversationId != null) {
      _socket.subscribeChat(_conversationId!);
      await _loadMessages();
    } else {
      if (mounted) setState(() => _loading = false);
    }
    _socket.onMessageNew(_onIncoming);
    _socket.onChatRead(_onChatRead);
    _socket.onChatDelivered(_onChatDelivered);
  }

  void _onChatRead(dynamic data) {
    if (data is! Map || data['user_id']?.toString() == _myId) return;
    final id = data['last_read_message_id']?.toString();
    if (id != null && mounted) setState(() => _otherReadId = id);
  }

  void _onChatDelivered(dynamic data) {
    if (data is! Map || data['user_id']?.toString() == _myId) return;
    final id = data['last_delivered_message_id']?.toString();
    if (id != null && mounted) setState(() => _otherDeliveredId = id);
  }

  void _onIncoming(dynamic data) {
    if (data is! Map) return;
    if (data['conversation_id']?.toString() != _conversationId) return;
    final msg = MessageModel.fromJson(Map<String, dynamic>.from(data));
    if (_messages.any((m) => m.id == msg.id)) return; // dedupe (e.g. my own echo)
    setState(() => _messages.add(msg));
    _jumpToBottom();
    if (_conversationId != null) {
      _repo.markRead(_conversationId!, msg.id);
    }
  }

  Future<void> _loadMessages() async {
    final res = await _repo.getMessages(_conversationId!);
    if (!mounted) return;
    res.when(
      success: (page) {
        setState(() {
          _messages = page.messages;
          _otherReadId = page.otherLastReadMessageId;
          _otherDeliveredId = page.otherLastDeliveredMessageId;
          _loading = false;
        });
        // reverse ListView keeps us pinned to the newest message — no manual scroll,
        // so the chat opens straight at the end (like WhatsApp), no visible jump.
      },
      failure: (_, __) => setState(() => _loading = false),
    );
  }

  /// With a reverse ListView, index 0 is the bottom; nudge to it only when the
  /// user is already near the bottom so we don't yank them away from history.
  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.pixels < 200) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    if (_conversationId != null) _socket.unsubscribeChat(_conversationId!);
    _socket.off('message.new');
    _socket.off('chat.read');
    _socket.off('chat.delivered');
    _recordTimer?.cancel();
    _recorder.dispose();
    _textController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── sending ────────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final res = await _repo.sendText(
      conversationId: _conversationId,
      toUserId: _conversationId == null ? widget.otherUserId : null,
      body: body,
    );
    if (!mounted) return;
    res.when(
      success: (msg) {
        _textController.clear();
        _adoptConversation(msg);
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _jumpToBottom();
      },
      failure: (m, __) {
        setState(() => _sending = false);
        _toast(m);
      },
    );
  }

  void _adoptConversation(MessageModel msg) {
    if (_conversationId == null && msg.conversationId.isNotEmpty) {
      _conversationId = msg.conversationId;
      _socket.subscribeChat(_conversationId!);
    }
  }

  Future<void> _sendMediaFile(String path, String type) async {
    setState(() => _sending = true);
    final up = await _repo.uploadMedia(path);
    if (!mounted) return;
    if (up is! Success<UploadedMedia>) {
      setState(() => _sending = false);
      _toast('Upload failed');
      return;
    }
    final res = await _repo.sendMedia(
      conversationId: _conversationId,
      toUserId: _conversationId == null ? widget.otherUserId : null,
      type: type,
      mediaUrl: up.data.url,
      durationSeconds: type == 'voice' && _recordElapsed.inSeconds > 0 ? _recordElapsed.inSeconds : null,
    );
    if (!mounted) return;
    res.when(
      success: (msg) {
        _adoptConversation(msg);
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _jumpToBottom();
      },
      failure: (m, __) {
        setState(() => _sending = false);
        _toast(m);
      },
    );
  }

  // ── voice recording ─────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _toast('Microphone permission needed');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _recordPath = path;
      _recordElapsed = Duration.zero;
      setState(() => _isRecording = true);
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordElapsed += const Duration(seconds: 1));
      });
    } catch (_) {
      _toast('Could not start recording');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _recordPath = null;
      _recordElapsed = Duration.zero;
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    final finalPath = path ?? _recordPath;
    final elapsed = _recordElapsed;
    setState(() => _isRecording = false);
    if (finalPath == null || elapsed.inSeconds < 1) {
      _toast('Recording too short');
      setState(() => _recordElapsed = Duration.zero);
      return;
    }
    await _sendMediaFile(finalPath, 'voice');
    setState(() => _recordElapsed = Duration.zero);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
              text: widget.contactName.isNotEmpty ? widget.contactName : 'U',
              imageUrl: widget.contactPhotoUrl,
              size: 36,
              gradient: AppColors.avatarBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contactName, style: AppTextStyles.bodyBold,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (widget.isOnline)
                    Text('online',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.ok, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.ink2),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesArea()),
            if (_showAttachBar) _buildAttachmentPanel(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 46, color: AppColors.muted),
              const SizedBox(height: 10),
              Text('Say salam 👋', style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Send the first message to start the chat.',
                  style: AppTextStyles.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    // Precompute how far the other side has read/delivered (by position), so each
    // of my bubbles can show the right tick without rescanning the whole list.
    final readIdx = _otherReadId == null ? -1 : _messages.indexWhere((m) => m.id == _otherReadId);
    final deliveredIdx = _otherDeliveredId == null ? -1 : _messages.indexWhere((m) => m.id == _otherDeliveredId);

    // reverse:true → index 0 is the newest, pinned to the bottom. Opening the chat
    // lands at the latest message with no scroll animation, and new messages slot in
    // at the bottom smoothly — exactly like WhatsApp.
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final realIndex = _messages.length - 1 - i;
        return _buildMessageBubble(_messages[realIndex], realIndex, readIdx, deliveredIdx);
      },
    );
  }

  Widget _buildInputBar() {
    if (_isRecording) return _buildRecordingBar();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.hair)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The rounded input pill: attach · text · camera (WhatsApp layout).
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, maxHeight: 130),
                padding: const EdgeInsets.only(left: 4, right: 10),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _showAttachBar ? Icons.close_rounded : Icons.add_rounded,
                        color: AppColors.ink2,
                        size: 24,
                      ),
                      onPressed: () => setState(() => _showAttachBar = !_showAttachBar),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          style: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.3),
                          cursorColor: AppColors.brand,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),
                    if (!_hasText) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: InkWell(
                          onTap: () async {
                            final file = await ImagePickerHelper.pickFromCamera();
                            if (file != null) _sendMediaFile(file.path, 'image');
                          },
                          child: const Icon(Icons.camera_alt_rounded, size: 22, color: AppColors.mut),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            _buildSendOrMicButton(),
          ],
        ),
      ),
    );
  }

  /// Mic when the field is empty, Send (paper plane) the moment the user types.
  Widget _buildSendOrMicButton() {
    final isSend = _hasText;
    return GestureDetector(
      onTap: _sending ? null : (isSend ? _sendText : _startRecording),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 48,
        height: 48,
        decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
        child: _sending
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(isSend ? Icons.send_rounded : Icons.mic_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildRecordingBar() {
    final m = _recordElapsed.inMinutes;
    final s = (_recordElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 26),
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 4),
          const _PulsingDot(),
          const SizedBox(width: 10),
          Text('Recording  $m:$s', style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink)),
          const Spacer(),
          GestureDetector(
            onTap: _sending ? null : _stopAndSendRecording,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 21),
            ),
          ),
        ],
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
          _AttachOption(
            icon: Icons.camera_alt_rounded, label: 'Camera', color: AppColors.brand, bg: AppColors.brand50,
            onTap: () async {
              setState(() => _showAttachBar = false);
              final file = await ImagePickerHelper.pickFromCamera();
              if (file != null) _sendMediaFile(file.path, 'image');
            },
          ),
          _AttachOption(
            icon: Icons.image_rounded, label: 'Gallery', color: AppColors.purpleImage, bg: AppColors.purpleBg,
            onTap: () async {
              setState(() => _showAttachBar = false);
              final file = await ImagePickerHelper.pickFromGallery();
              if (file != null) _sendMediaFile(file.path, 'image');
            },
          ),
          _AttachOption(
            icon: Icons.videocam_rounded, label: 'Video', color: AppColors.pinkVideo, bg: AppColors.pinkBg,
            onTap: () async {
              setState(() => _showAttachBar = false);
              final file = await ImagePickerHelper.pickVideoFromGallery();
              if (file != null) _sendMediaFile(file.path, 'video');
            },
          ),
          _AttachOption(
            icon: Icons.mic_rounded, label: 'Voice', color: AppColors.ok, bg: AppColors.ok50,
            onTap: () {
              setState(() => _showAttachBar = false);
              _startRecording();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, int index, int readIdx, int deliveredIdx) {
    final isMe = msg.senderId == _myId;
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
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: AppShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(msg, isMe),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.timeLabel,
                  style: AppTextStyles.caption.copyWith(
                      color: isMe ? AppColors.white90 : AppColors.mut, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _tick(index, readIdx, deliveredIdx),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// WhatsApp ticks on my messages: single ✓ = sent, double ✓✓ grey = delivered,
  /// double ✓✓ green = read/seen.
  Widget _tick(int index, int readIdx, int deliveredIdx) {
    if (readIdx >= 0 && index <= readIdx) {
      return const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF53E27A));
    }
    if (deliveredIdx >= 0 && index <= deliveredIdx) {
      return const Icon(Icons.done_all_rounded, size: 15, color: Colors.white70);
    }
    return const Icon(Icons.done_rounded, size: 15, color: Colors.white70);
  }

  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    switch (msg.type) {
      case 'voice':
        return VoiceBubble(
          url: msg.media?.url ?? '',
          durationSeconds: msg.media?.durationSeconds,
          isMe: isMe,
        );
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            msg.media?.url ?? '',
            width: 200,
            fit: BoxFit.cover,
            loadingBuilder: (c, w, p) => p == null
                ? w
                : Container(
                    width: 200, height: 150, alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
            errorBuilder: (c, _, __) => Container(
                width: 200, height: 120, color: AppColors.soft,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.mut)),
          ),
        );
      case 'video':
        final url = msg.media?.url ?? '';
        return GestureDetector(
          onTap: url.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url))),
          child: Container(
            width: 200,
            height: 130,
            decoration: BoxDecoration(gradient: AppColors.duskMesh, borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44)),
          ),
        );
      default:
        return Text(
          msg.body ?? '',
          style: AppTextStyles.body.copyWith(color: isMe ? Colors.white : AppColors.ink),
        );
    }
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
        child: Container(width: 10, height: 10,
            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
      );
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.captionBold.copyWith(color: AppColors.ink2)),
        ],
      ),
    );
  }
}
