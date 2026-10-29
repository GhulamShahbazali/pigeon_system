import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';

/// One notification row. The backend feed returns a compact shape
/// (`id, type, entity_type, entity_id, is_read, actors, entity, data,
/// created_at`); the human text/icon are derived here from `type` + `data`.
/// `data` carries the granular detail that `entity_id` alone can't convey
/// (participant name, pigeon name, landing time, contact, tournament title).
class NotificationModel {
  final String id;
  final String type;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final int actorCount;
  final String? firstActorName;
  final String? firstActorPhoto;
  final String? entityTitle;
  final DateTime createdAt;
  // Granular detail (from `data`)
  final String? participantName;
  final String? pigeonName;
  final DateTime? landingTime;
  final String? contactNo;

  NotificationModel({
    required this.id,
    required this.type,
    this.entityType,
    this.entityId,
    required this.isRead,
    required this.actorCount,
    this.firstActorName,
    this.firstActorPhoto,
    this.entityTitle,
    required this.createdAt,
    this.participantName,
    this.pigeonName,
    this.landingTime,
    this.contactNo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actorsRaw = json['actors'];
    final actors = actorsRaw is List ? actorsRaw : const [];
    final firstActor = actors.isNotEmpty && actors.first is Map ? actors.first as Map : null;
    final entity = json['entity'] is Map ? json['entity'] as Map : null;
    final data = json['data'] is Map ? json['data'] as Map : null;
    // Fallback to actor_ids length when the hydrated actors list is absent.
    final count = actors.isNotEmpty
        ? actors.length
        : (json['actor_ids'] is List ? (json['actor_ids'] as List).length : 0);
    // Tournament title: the hydrated entity title, else the copy kept in data.
    final title = entity?['title']?.toString() ?? data?['tournament_title']?.toString();
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      isRead: json['is_read'] == true,
      actorCount: count,
      firstActorName: firstActor?['display_name']?.toString(),
      firstActorPhoto: firstActor?['photo_url']?.toString(),
      entityTitle: title,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      participantName: data?['participant_name']?.toString(),
      pigeonName: data?['pigeon_name']?.toString(),
      landingTime: DateTime.tryParse(data?['landing_time']?.toString() ?? '')?.toLocal(),
      contactNo: data?['contact_no']?.toString(),
    );
  }

  /// "Ahmed Loft", "Ahmed Loft + 3 others", or "Someone" — localized.
  String _localizedWho(AppStrings s) {
    final name = firstActorName;
    if (name == null || name.isEmpty) {
      return actorCount > 1 ? s.peopleCount(actorCount) : s.someoneLabel;
    }
    if (actorCount > 1) return s.andOthers(name, actorCount - 1);
    return name;
  }

  /// Landing time as local HH:MM, or null.
  String? get _landingHhmm {
    final t = landingTime;
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Granular, localized headline for the row. Carries the specifics the
  /// backend now sends in `data` (who joined, which pigeon landed and when).
  String localizedTitle(AppStrings s) {
    final who = _localizedWho(s);
    switch (type) {
      case 'new_follower':
        return s.notifNewFollower(who);
      case 'tournament_created':
        return s.notifTournamentCreated(who, entityTitle);
      case 'participant_added':
        return s.notifParticipantAdded(participantName, entityTitle);
      case 'tournament_day_results':
        return s.notifDayResults(participantName, pigeonName, _landingHhmm, entityTitle);
      case 'content_like':
        return s.notifContentLike(who, entityType == 'record');
      case 'record_live_started':
        return s.notifLiveNow(who);
      case 'message_request':
        return s.notifMessageRequest(who);
      case 'moderation':
        return s.notifModeration;
      default:
        return s.notifGeneric;
    }
  }

  /// Optional secondary line — the participant's contact number on a day-result
  /// (so a follower can reach the loft). Null when there's nothing extra to show.
  String? get detailLine =>
      (type == 'tournament_day_results' && contactNo != null && contactNo!.isNotEmpty)
          ? contactNo
          : null;

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

  String localizedTimeAgo(AppStrings s) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return s.timeJustNow;
    if (diff.inMinutes < 60) return s.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.timeHoursAgo(diff.inHours);
    if (diff.inDays == 1) return s.timeYesterday;
    if (diff.inDays < 7) return s.timeDaysAgo(diff.inDays);
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
