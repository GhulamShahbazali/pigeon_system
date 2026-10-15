import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import 'models/chat_models.dart';

/// Uploaded media descriptor returned by POST /media.
class UploadedMedia {
  final String url;
  final String kind;
  UploadedMedia({required this.url, required this.kind});
}

/// A page of messages plus the OTHER participant's read/delivered pointers
/// (for rendering WhatsApp-style sent-ticks on my own messages).
class MessagesPage {
  final List<MessageModel> messages;
  final String? otherLastReadMessageId;
  final String? otherLastDeliveredMessageId;
  MessagesPage({
    required this.messages,
    this.otherLastReadMessageId,
    this.otherLastDeliveredMessageId,
  });
}

class ChatRepository {
  final ApiClient _api;
  ChatRepository(this._api);

  /// Inbox conversations — the backend returns each row already enriched with the
  /// other participant's name/photo and a last-message preview, so this is ONE call
  /// (no N+1), which matters a lot on a high-latency DB.
  Future<Result<List<ConversationModel>>> getInbox() {
    return _api.get<List<ConversationModel>>(
      '/conversations',
      fromJson: (data) => (data as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Pending message requests — conversations where I'm the recipient and the
  /// sender's first message hasn't been accepted yet.
  Future<Result<List<ConversationModel>>> getRequests() {
    return _api.get<List<ConversationModel>>(
      '/conversations/requests',
      fromJson: (data) => (data as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Accept a request → both sides can message freely.
  Future<Result<void>> acceptRequest(String conversationId) {
    return _api.post<void>('/conversations/$conversationId/accept');
  }

  /// Decline/delete a request.
  Future<Result<void>> declineRequest(String conversationId) {
    return _api.delete<void>('/conversations/$conversationId/request');
  }

  /// Fetch a user's profile (name + photo) — used when opening a chat directly.
  Future<Result<Map<String, dynamic>>> getUser(String userId) {
    return _api.get<Map<String, dynamic>>(
      '/users/$userId',
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }

  /// Messages for a conversation (oldest → newest) plus the other side's read/
  /// delivered pointers. The API returns `{ messages:[newest first], … }`.
  Future<Result<MessagesPage>> getMessages(String conversationId, {int limit = 50}) {
    return _api.get<MessagesPage>(
      '/conversations/$conversationId/messages',
      queryParameters: {'limit': limit},
      fromJson: (data) {
        final map = data as Map<String, dynamic>;
        final list = ((map['messages'] as List?) ?? [])
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return MessagesPage(
          messages: list,
          otherLastReadMessageId: map['other_last_read_message_id']?.toString(),
          otherLastDeliveredMessageId: map['other_last_delivered_message_id']?.toString(),
        );
      },
    );
  }

  /// Send a text message. Provide either [conversationId] (existing chat) or
  /// [toUserId] (first message / message request).
  Future<Result<MessageModel>> sendText({
    String? conversationId,
    String? toUserId,
    required String body,
  }) {
    return _api.post<MessageModel>(
      '/messages',
      data: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (toUserId != null) 'to_user_id': toUserId,
        'type': 'text',
        'body': body,
      },
      fromJson: (d) => MessageModel.fromJson(d as Map<String, dynamic>),
    );
  }

  /// Upload a media file (voice/image/video) and get back its URL + kind.
  Future<Result<UploadedMedia>> uploadMedia(String filePath) {
    return _api.upload<UploadedMedia>(
      '/media',
      filePath: filePath,
      fromJson: (d) => UploadedMedia(
        url: (d as Map<String, dynamic>)['url']?.toString() ?? '',
        kind: d['kind']?.toString() ?? 'image',
      ),
    );
  }

  /// Send a media message (after uploading). [type] is voice|image|video.
  Future<Result<MessageModel>> sendMedia({
    String? conversationId,
    String? toUserId,
    required String type,
    required String mediaUrl,
    int? durationSeconds,
  }) {
    return _api.post<MessageModel>(
      '/messages',
      data: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (toUserId != null) 'to_user_id': toUserId,
        'type': type,
        'media_url': mediaUrl,
        if (durationSeconds != null) 'media_duration_seconds': durationSeconds,
      },
      fromJson: (d) => MessageModel.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<Result<void>> markRead(String conversationId, String uptoMessageId) {
    return _api.post<void>(
      '/conversations/$conversationId/read',
      data: {'up_to_message_id': uptoMessageId},
    );
  }
}
