import 'tournament_card_model.dart';

class TournamentDayModel {
  final String id;
  final int dayNumber;
  final String date;

  TournamentDayModel({
    required this.id,
    required this.dayNumber,
    required this.date,
  });

  factory TournamentDayModel.fromJson(Map<String, dynamic> json) {
    return TournamentDayModel(
      id: json['id']?.toString() ?? '',
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      date: json['date']?.toString() ?? '',
    );
  }
}

class ParticipantRowModel {
  final String id;
  final String name;
  final String? photoUrl;
  final int? position;
  final int? overallAvgSeconds;
  final int overallReturnedCount;
  final String? contactNo;
  final String? phone;

  ParticipantRowModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.position,
    this.overallAvgSeconds,
    required this.overallReturnedCount,
    this.contactNo,
    this.phone,
  });

  factory ParticipantRowModel.fromJson(Map<String, dynamic> json) {
    return ParticipantRowModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      position: (json['position'] as num?)?.toInt(),
      overallAvgSeconds: (json['overall_avg_seconds'] as num?)?.toInt(),
      overallReturnedCount: (json['overall_returned_count'] as num?)?.toInt() ?? 0,
      contactNo: json['contact_no']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  String get formattedAverage {
    if (overallAvgSeconds == null || overallAvgSeconds == 0) return '0h 00m';
    final hours = overallAvgSeconds! ~/ 3600;
    final minutes = (overallAvgSeconds! % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}

class TournamentDetailModel {
  final String id;
  final String title;
  final String? rules;
  final String? description;
  final String? coverUrl;
  final String scheduleType;
  final int numDays;
  final int pigeonCount;
  final String status;
  final String? organizerContact;
  final int? overallAvgSeconds;
  final int likeCount;
  final int viewCount;
  final int followerCount;
  final bool isFollowing;
  final bool isLiked;
  final bool isOrganizer;
  final String linkSlug;
  final TournamentOrganizerModel? organizer;
  final List<TournamentDayModel> days;

  TournamentDetailModel({
    required this.id,
    required this.title,
    this.rules,
    this.description,
    this.coverUrl,
    required this.scheduleType,
    required this.numDays,
    required this.pigeonCount,
    required this.status,
    this.organizerContact,
    this.overallAvgSeconds,
    required this.likeCount,
    required this.viewCount,
    required this.followerCount,
    this.isFollowing = false,
    this.isLiked = false,
    this.isOrganizer = false,
    required this.linkSlug,
    this.organizer,
    required this.days,
  });

  factory TournamentDetailModel.fromJson(Map<String, dynamic> json) {
    return TournamentDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      rules: json['rules']?.toString(),
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      scheduleType: json['schedule_type']?.toString() ?? 'every_day',
      numDays: (json['num_days'] as num?)?.toInt() ?? 1,
      pigeonCount: (json['pigeon_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      organizerContact: json['organizer_contact']?.toString(),
      overallAvgSeconds: (json['overall_avg_seconds'] as num?)?.toInt(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] == true,
      isLiked: json['is_liked'] == true,
      isOrganizer: json['is_organizer'] == true,
      linkSlug: json['link_slug']?.toString() ?? '',
      organizer: json['organizer'] != null
          ? TournamentOrganizerModel.fromJson(json['organizer'] as Map<String, dynamic>)
          : null,
      days: (json['days'] as List?)
              ?.map((e) => TournamentDayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get formattedOverallAverage {
    if (overallAvgSeconds == null || overallAvgSeconds == 0) return '0h 00m';
    final hours = overallAvgSeconds! ~/ 3600;
    final minutes = (overallAvgSeconds! % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}
