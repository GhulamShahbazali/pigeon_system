import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';

/// A person shown in Find friends / search results (reuses the backend
/// `user_card` shape from the discovery + search endpoints).
class UserCardModel {
  final String id;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? city;
  final String? countryCode;
  final int followerCount;
  bool isFollowing;

  UserCardModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.city,
    this.countryCode,
    this.followerCount = 0,
    this.isFollowing = false,
  });

  factory UserCardModel.fromJson(Map<String, dynamic> json) => UserCardModel(
        id: json['id']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? 'Flyer',
        username: json['username']?.toString() ?? 'flyer',
        photoUrl: json['photo_url']?.toString(),
        city: json['city']?.toString(),
        countryCode: json['country_code']?.toString(),
        followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
        isFollowing: json['is_following'] == true,
      );

  String get handle => '@$username';

  String get followersLabel {
    if (followerCount >= 1000) {
      final k = (followerCount / 1000);
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k followers';
    }
    return '$followerCount followers';
  }
}

class DiscoveryRepository {
  final ApiClient _api;
  DiscoveryRepository(this._api);

  static List<UserCardModel> _parseList(dynamic data) => data is List
      ? data.map((e) => UserCardModel.fromJson(e as Map<String, dynamic>)).toList()
      : <UserCardModel>[];

  /// People you don't follow yet (ordered by follower count / recent activity).
  Future<Result<List<UserCardModel>>> suggestions({int limit = 20}) {
    return _api.get<List<UserCardModel>>(
      '/discovery/suggestions',
      queryParameters: {'limit': limit},
      fromJson: _parseList,
    );
  }

  /// Search users by name or @username.
  Future<Result<List<UserCardModel>>> searchUsers(String q, {int limit = 20}) {
    return _api.get<List<UserCardModel>>(
      '/search/users',
      queryParameters: {'q': q, 'limit': limit},
      fromJson: _parseList,
    );
  }
}
