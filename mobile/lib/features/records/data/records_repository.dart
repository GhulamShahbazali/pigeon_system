import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';

/// Formats a flight duration/average into standard HH:MM format (e.g. 06:47, 01:20)
String formatRaceDuration(int? totalSeconds) {
  final s = totalSeconds ?? 0;
  if (s <= 0) return '00:00';
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class LiveRecordOwnerModel {
  final String id;
  final String displayName;
  final String username;
  final String? photoUrl;

  LiveRecordOwnerModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.photoUrl,
  });

  factory LiveRecordOwnerModel.fromJson(Map<String, dynamic> json) {
    return LiveRecordOwnerModel(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'username': username,
        'photo_url': photoUrl,
      };
}

class LiveRecordPreviewModel {
  final String id;
  final int? totalAvgSeconds;
  final int returnedCount;
  final int totalPigeons;
  final int likeCount;
  final int viewCount;
  final LiveRecordOwnerModel? owner;

  LiveRecordPreviewModel({
    required this.id,
    this.totalAvgSeconds,
    required this.returnedCount,
    required this.totalPigeons,
    required this.likeCount,
    required this.viewCount,
    this.owner,
  });

  factory LiveRecordPreviewModel.fromJson(Map<String, dynamic> json) {
    return LiveRecordPreviewModel(
      id: json['id']?.toString() ?? '',
      totalAvgSeconds: (json['total_avg_seconds'] as num?)?.toInt(),
      returnedCount: (json['returned_count'] as num?)?.toInt() ?? 0,
      totalPigeons: (json['total_pigeons'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      owner: json['owner'] != null
          ? LiveRecordOwnerModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'total_avg_seconds': totalAvgSeconds,
        'returned_count': returnedCount,
        'total_pigeons': totalPigeons,
        'like_count': likeCount,
        'view_count': viewCount,
        'owner': owner?.toJson(),
      };
}

class PersonalRecordModel {
  final String id;
  final String recordDate;
  final String flyTime;
  final String? releaseAt;
  final int totalPigeons;
  final String privacy;
  final String status;
  final int? totalAvgSeconds;
  final int returnedCount;
  final int likeCount;
  final int viewCount;
  final String? wentLiveAt;

  PersonalRecordModel({
    required this.id,
    required this.recordDate,
    required this.flyTime,
    this.releaseAt,
    required this.totalPigeons,
    required this.privacy,
    required this.status,
    this.totalAvgSeconds,
    required this.returnedCount,
    required this.likeCount,
    required this.viewCount,
    this.wentLiveAt,
  });

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordModel(
      id: json['id']?.toString() ?? '',
      recordDate: json['record_date']?.toString() ?? '',
      flyTime: json['fly_time']?.toString() ?? '',
      releaseAt: json['release_at']?.toString(),
      totalPigeons: (json['total_pigeons'] as num?)?.toInt() ?? 0,
      privacy: json['privacy']?.toString() ?? 'private',
      status: json['status']?.toString() ?? 'open',
      totalAvgSeconds: (json['total_avg_seconds'] as num?)?.toInt(),
      returnedCount: (json['returned_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      wentLiveAt: json['went_live_at']?.toString(),
    );
  }

  bool get isLive => privacy == 'live' && status == 'open';

  String get formattedAverage => formatRaceDuration(totalAvgSeconds);

  String get formattedFlyTime {
    try {
      final parts = flyTime.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = parts[1].padLeft(2, '0');
        final hour = h % 12 == 0 ? 12 : h % 12;
        final period = h >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:$m $period';
      }
    } catch (_) {}
    return flyTime;
  }
}

class RecordsRepository {
  final ApiClient _apiClient;

  RecordsRepository(this._apiClient);

  Future<Result<List<PersonalRecordModel>>> getMyRecords() async {
    return _apiClient.get<List<PersonalRecordModel>>(
      '/me/records',
      fromJson: (data) {
        if (data is List) {
          return data
              .map((e) => PersonalRecordModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<Result<List<LiveRecordPreviewModel>>> getLiveNow() async {
    return _apiClient.get<List<LiveRecordPreviewModel>>(
      '/records/live',
      fromJson: (data) {
        if (data is List) {
          return data
              .map((e) => LiveRecordPreviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<Result<PersonalRecordModel>> createRecord({
    required String recordDate,
    required String flyTime,
    required int totalPigeons,
    required String privacy,
  }) async {
    return _apiClient.post<PersonalRecordModel>(
      '/me/records',
      data: {
        'record_date': recordDate,
        'fly_time': flyTime,
        'total_pigeons': totalPigeons,
        'privacy': privacy,
      },
      fromJson: (data) => PersonalRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<PersonalRecordModel>> goLive(String recordId) async {
    return _apiClient.post<PersonalRecordModel>(
      '/records/$recordId/go-live',
      fromJson: (data) => PersonalRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<RecordDetailModel>> getRecordDetail(String recordId) async {
    return _apiClient.get<RecordDetailModel>(
      '/records/$recordId',
      fromJson: (data) => RecordDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<RecordPigeonModel>> addPigeon(
    String recordId, {
    required String pigeonName,
    required DateTime landingTime,
  }) async {
    return _apiClient.post<RecordPigeonModel>(
      '/records/$recordId/pigeons',
      data: {
        'pigeon_name': pigeonName,
        'landing_time': landingTime.toUtc().toIso8601String(),
      },
      fromJson: (data) => RecordPigeonModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<void>> toggleLike(String recordId, bool like) async {
    if (like) {
      return _apiClient.post<void>('/records/$recordId/like');
    } else {
      return _apiClient.delete<void>('/records/$recordId/like');
    }
  }

  Future<Result<void>> endRecord(String recordId) async {
    return _apiClient.post<void>('/records/$recordId/end');
  }
}

class RecordPigeonModel {
  final String id;
  final String pigeonName;
  final String landingTime;
  final int durationSeconds;

  RecordPigeonModel({
    required this.id,
    required this.pigeonName,
    required this.landingTime,
    required this.durationSeconds,
  });

  factory RecordPigeonModel.fromJson(Map<String, dynamic> json) {
    return RecordPigeonModel(
      id: json['id']?.toString() ?? '',
      pigeonName: json['pigeon_name']?.toString() ?? '',
      landingTime: json['landing_time']?.toString() ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedDuration => formatRaceDuration(durationSeconds);

  String get formattedLandingTime {
    try {
      final dt = DateTime.parse(landingTime).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return landingTime;
    }
  }
}

class RecordDetailModel {
  final String id;
  final String recordDate;
  final String flyTime;
  final String? releaseAt;
  final int totalPigeons;
  final String privacy;
  final String status;
  final int? totalAvgSeconds;
  final int returnedCount;
  final int likeCount;
  final int viewCount;
  final bool isOwner;
  final bool isLiked;
  final LiveRecordOwnerModel? owner;
  final List<RecordPigeonModel> pigeons;

  RecordDetailModel({
    required this.id,
    required this.recordDate,
    required this.flyTime,
    this.releaseAt,
    required this.totalPigeons,
    required this.privacy,
    required this.status,
    this.totalAvgSeconds,
    required this.returnedCount,
    required this.likeCount,
    required this.viewCount,
    required this.isOwner,
    required this.isLiked,
    this.owner,
    required this.pigeons,
  });

  factory RecordDetailModel.fromJson(Map<String, dynamic> json) {
    final pigeonsRaw = json['pigeons'];
    final List<RecordPigeonModel> pigeonsList = [];
    if (pigeonsRaw is List) {
      for (final p in pigeonsRaw) {
        if (p is Map<String, dynamic>) {
          pigeonsList.add(RecordPigeonModel.fromJson(p));
        }
      }
    }

    return RecordDetailModel(
      id: json['id']?.toString() ?? '',
      recordDate: json['record_date']?.toString() ?? '',
      flyTime: json['fly_time']?.toString() ?? '',
      releaseAt: json['release_at']?.toString(),
      totalPigeons: (json['total_pigeons'] as num?)?.toInt() ?? 0,
      privacy: json['privacy']?.toString() ?? 'private',
      status: json['status']?.toString() ?? 'open',
      totalAvgSeconds: (json['total_avg_seconds'] as num?)?.toInt(),
      returnedCount: (json['returned_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isOwner: json['is_owner'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      owner: json['owner'] != null
          ? LiveRecordOwnerModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      pigeons: pigeonsList,
    );
  }

  bool get isLive => privacy == 'live' && status == 'open';

  int get totalDurationSeconds {
    if (pigeons.isNotEmpty) {
      return pigeons.fold<int>(0, (sum, p) => sum + p.durationSeconds);
    }
    return totalAvgSeconds ?? 0;
  }

  String get formattedAverage => formatRaceDuration(totalDurationSeconds);

  String get formattedFlyTime {
    try {
      final parts = flyTime.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = parts[1].padLeft(2, '0');
        final hour = h % 12 == 0 ? 12 : h % 12;
        final period = h >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:$m $period';
      }
    } catch (_) {}
    return flyTime;
  }
}
