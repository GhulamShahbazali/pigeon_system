// Chat domain models mapped from the backend REST + socket payloads.

class ChatMediaModel {
  final String url;
  final String kind; // voice | image | video
  final int? durationSeconds;
  final String? thumbUrl;

  ChatMediaModel({
    required this.url,
    required this.kind,
    this.durationSeconds,
    this.thumbUrl,
  });

  factory ChatMediaModel.fromJson(Map<String, dynamic> json) => ChatMediaModel(
        url: json['url']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'image',
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
        thumbUrl: json['thumb_url']?.toString(),
      );
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String type; // text | voice | image | video
  final String? body;
  final ChatMediaModel? media;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.body,
    this.media,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id']?.toString() ?? '',
        conversationId: json['conversation_id']?.toString() ?? '',
        senderId: json['sender_id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'text',
        body: json['body']?.toString(),
        media: json['media'] is Map<String, dynamic>
            ? ChatMediaModel.fromJson(json['media'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
      );

  String get timeLabel {
    final h = createdAt.hour;
    final m = createdAt.minute.toString().padLeft(2, '0');
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$hour12:$m $ampm';
  }
}

/// One inbox row — the conversation plus the other participant's profile.
class ConversationModel {
  final String id;
  final String status; // active | pending
  final DateTime? lastMessageAt;
  final String? otherUserId;
  final String otherName;
  final String? otherPhotoUrl;
  final String? lastMessagePreview;

  ConversationModel({
    required this.id,
    required this.status,
    this.lastMessageAt,
    this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
    this.lastMessagePreview,
  });

  ConversationModel copyWith({
    String? otherName,
    String? otherPhotoUrl,
    String? lastMessagePreview,
  }) =>
      ConversationModel(
        id: id,
        status: status,
        lastMessageAt: lastMessageAt,
        otherUserId: otherUserId,
        otherName: otherName ?? this.otherName,
        otherPhotoUrl: otherPhotoUrl ?? this.otherPhotoUrl,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      );

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'] as Map<String, dynamic>?;
    final last = json['last_message'] as Map<String, dynamic>?;
    String? preview;
    if (last != null) {
      switch (last['type']?.toString()) {
        case 'voice':
          preview = '🎤 Voice message';
          break;
        case 'image':
          preview = '📷 Photo';
          break;
        case 'video':
          preview = '🎬 Video';
          break;
        default:
          preview = last['body']?.toString();
      }
    }
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      lastMessageAt: DateTime.tryParse(json['last_message_at']?.toString() ?? '')?.toLocal(),
      otherUserId: (other?['id'] ?? json['other_user_id'])?.toString(),
      otherName: other?['display_name']?.toString() ?? 'Pigeon fancier',
      otherPhotoUrl: other?['photo_url']?.toString(),
      lastMessagePreview: preview,
    );
  }

  String get timeLabel {
    final t = lastMessageAt;
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
      return '$hour12:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
    }
    final diff = now.difference(t).inDays;
    if (diff == 1) return 'Yest';
    if (diff < 7) return '${diff}d';
    return '${t.day}/${t.month}';
  }
}
