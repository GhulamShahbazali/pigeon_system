import 'package:socket_io_client/socket_io_client.dart' as io;
import '../local_storage/secure_storage_service.dart';
import '../../config/env/app_env.dart';

/// Thin Socket.io client over the backend gateway. Joins rooms and exposes the
/// real-time events the UI listens to (new posts, live counts, tournament updates).
class SocketService {
  final SecureStorageService _storage;
  io.Socket? _socket;

  SocketService(this._storage);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await _storage.getToken();
    _socket = io.io(
      AppEnv.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket!.connect();
  }

  // ── room subscriptions (match the backend gateway SubscribeMessage handlers) ──
  void subscribeFeed() => _socket?.emit('feed.subscribe');
  void unsubscribeFeed() => _socket?.emit('feed.unsubscribe');
  void subscribePostCounts(String postId) =>
      _socket?.emit('post.counts.subscribe', {'post_id': postId});
  void subscribeTournament(String id) =>
      _socket?.emit('tournament.subscribe', {'tournament_id': id});
  void subscribeChat(String conversationId) =>
      _socket?.emit('chat.subscribe', {'conversation_id': conversationId});
  void unsubscribeChat(String conversationId) =>
      _socket?.emit('chat.unsubscribe', {'conversation_id': conversationId});

  // ── event listeners ──────────────────────────────────────────────────────
  void onPostNew(void Function(dynamic data) cb) => _socket?.on('post.new', cb);
  void onPostCounts(void Function(dynamic data) cb) => _socket?.on('post.counts', cb);
  void onTournamentUpdate(void Function(dynamic data) cb) =>
      _socket?.on('tournament.update', cb);
  void onNotification(void Function(dynamic data) cb) =>
      _socket?.on('notification.new', cb);
  void onMessageNew(void Function(dynamic data) cb) =>
      _socket?.on('message.new', cb);
  void onChatRead(void Function(dynamic data) cb) =>
      _socket?.on('chat.read', cb);
  void onChatDelivered(void Function(dynamic data) cb) =>
      _socket?.on('chat.delivered', cb);
  void onMessageDeleted(void Function(dynamic data) cb) =>
      _socket?.on('message.deleted', cb);

  void off(String event) => _socket?.off(event);

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
