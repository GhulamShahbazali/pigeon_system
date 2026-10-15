import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';

class UserProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? bio;
  final String? city;
  final String? countryCode;
  final int followerCount;
  final int followingCount;
  final int tournamentCount;
  final int? recordCount;
  final int? postCount;
  final bool isFollowing;

  UserProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.bio,
    this.city,
    this.countryCode,
    this.followerCount = 0,
    this.followingCount = 0,
    this.tournamentCount = 0,
    this.recordCount,
    this.postCount,
    this.isFollowing = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>?;
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Flyer',
      username: json['username']?.toString() ?? 'flyer',
      photoUrl: json['photo_url']?.toString(),
      bio: json['bio']?.toString(),
      city: json['city']?.toString() ?? 'Lahore, PK',
      countryCode: json['country_code']?.toString(),
      followerCount: (stats?['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (stats?['following_count'] as num?)?.toInt() ?? 0,
      tournamentCount: (stats?['tournament_count'] as num?)?.toInt() ?? 0,
      postCount: (stats?['post_count'] as num?)?.toInt(),
      isFollowing: json['is_following'] == true,
    );
  }
}

class UserRepository {
  final ApiClient _api;

  UserRepository(this._api);

  Future<Result<UserProfileModel>> getMyProfile() async {
    return _api.get<UserProfileModel>(
      '/auth/me',
      fromJson: (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<UserProfileModel>> getUserProfile(String id) async {
    return _api.get<UserProfileModel>(
      '/users/$id',
      fromJson: (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<void>> follow(String id) => _api.post<void>('/users/$id/follow');
  Future<Result<void>> unfollow(String id) => _api.delete<void>('/users/$id/follow');

  /// Upload a profile photo file and get back its absolute public URL.
  /// Reuses the shared media endpoint (`POST /media`); the returned URL is then
  /// saved on the profile via [updateMyProfile] as `photo_url`.
  Future<Result<String>> uploadProfilePhoto(String filePath) {
    return _api.upload<String>(
      '/media',
      filePath: filePath,
      fromJson: (d) => (d as Map<String, dynamic>)['url']?.toString() ?? '',
    );
  }

  Future<Result<UserProfileModel>> updateMyProfile({
    String? displayName,
    String? username,
    String? bio,
    String? city,
    String? photoUrl,
  }) async {
    return _api.patch<UserProfileModel>(
      '/me',
      data: {
        if (displayName != null) 'display_name': displayName,
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
        if (city != null) 'city': city,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
      fromJson: (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
