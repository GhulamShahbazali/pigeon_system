import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';

/// One notification row. The backend feed returns a compact shape
/// (`id, type, entity_type, entity_id, is_read, actor_ids, created_at`); the
/// human text/icon are derived here from `type`.
class NotificationModel {
  final String id;
  final String type;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final int actorCount;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    this.entityType,
    this.entityId,
    required this.isRead,
    required this.actorCount,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actors = json['actor_ids'];
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      isRead: json['is_read'] == true,
      actorCount: actors is List ? actors.length : 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Human-readable label derived from the notification type (the feed does not
  /// yet hydrate actor names — that needs a backend change).
  String get title {
    final who = actorCount > 1 ? '$actorCount people' : 'Someone';
    switch (type) {
      case 'new_follower':
        return '$who started following you';
      case 'tournament_created':
        return 'Someone you follow created a new tournament';
      case 'participant_added':
        return 'A participant was added to a tournament you follow';
      case 'tournament_day_results':
        return 'New day results were posted in a tournament you follow';
      case 'content_like':
        return '$who liked your content';
      case 'record_live_started':
        return 'Someone you follow is flying live now';
      case 'message_request':
        return 'Someone sent you a message request';
      case 'moderation':
        return 'PigeonFly Team: an update about your content';
      default:
        return 'New activity';
    }
  }

  IconData get icon {
    switch (type) {
      case 'new_follower':
        return Icons.person_add_alt_1_rounded;
      case 'tournament_created':
        return Icons.add_circle_outline_rounded;
      case 'participant_added':
        return Icons.people_outline_rounded;
      case 'tournament_day_results':
        return Icons.emoji_events_rounded;
      case 'content_like':
        return Icons.favorite_rounded;
      case 'record_live_started':
        return Icons.remove_red_eye_outlined;
      case 'message_request':
        return Icons.chat_bubble_outline_rounded;
      case 'moderation':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get iconBg {
    switch (type) {
      case 'content_like':
        return AppColors.danger;
      case 'tournament_day_results':
        return AppColors.amber;
      case 'record_live_started':
        return AppColors.ok;
      default:
        return AppColors.brand;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}';
  }
}

class NotificationsRepository {
  final ApiClient _api;
  NotificationsRepository(this._api);

  Future<Result<List<NotificationModel>>> getFeed({int limit = 30}) {
    return _api.get<List<NotificationModel>>(
      '/notifications',
      queryParameters: {'limit': limit},
      fromJson: (data) => data is List
          ? data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList()
          : <NotificationModel>[],
    );
  }

  Future<Result<int>> unreadCount() {
    return _api.get<int>(
      '/notifications/unread-count',
      fromJson: (d) => (d is Map && d['unread_count'] is num)
          ? (d['unread_count'] as num).toInt()
          : 0,
    );
  }

  Future<Result<void>> markAllRead() => _api.post<void>('/notifications/read-all');

  Future<Result<void>> markRead(String id) => _api.post<void>('/notifications/$id/read');
}
