class TournamentOrganizerModel {
  final String id;
  final String displayName;
  final String username;
  final String? photoUrl;

  TournamentOrganizerModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.photoUrl,
  });

  factory TournamentOrganizerModel.fromJson(Map<String, dynamic> json) {
    return TournamentOrganizerModel(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class TournamentCardModel {
  final String id;
  final String title;
  final String? coverUrl;
  final String scheduleType;
  final int numDays;
  final int pigeonCount;
  final String status;
  final bool isLive;
  final int likeCount;
  final int viewCount;
  final int followerCount;
  final String linkSlug;
  final TournamentOrganizerModel? organizer;
  final String createdAt;

  TournamentCardModel({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.scheduleType,
    required this.numDays,
    required this.pigeonCount,
    required this.status,
    this.isLive = false,
    required this.likeCount,
    required this.viewCount,
    required this.followerCount,
    required this.linkSlug,
    this.organizer,
    required this.createdAt,
  });

  factory TournamentCardModel.fromJson(Map<String, dynamic> json) {
    return TournamentCardModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString(),
      scheduleType: json['schedule_type']?.toString() ?? 'every_day',
      numDays: (json['num_days'] as num?)?.toInt() ?? 1,
      pigeonCount: (json['pigeon_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      isLive: json['is_live'] as bool? ?? false,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      linkSlug: json['link_slug']?.toString() ?? '',
      organizer: json['organizer'] != null
          ? TournamentOrganizerModel.fromJson(json['organizer'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  String get scheduleDisplay => scheduleType == 'alternate_days' ? 'Alternate' : 'Every day';
  String get daysDisplay => '$numDays ${numDays == 1 ? 'day' : 'days'}';
}
