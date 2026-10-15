import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';

class PostAuthorModel {
  final String id;
  final String displayName;
  final String username;
  final String? photoUrl;

  PostAuthorModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.photoUrl,
  });

  factory PostAuthorModel.fromJson(Map<String, dynamic> json) {
    return PostAuthorModel(
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

class PostModel {
  final String id;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final int shareCount;
  final int viewCount;
  final bool isLiked;
  final PostAuthorModel author;
  final String createdAt;

  PostModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.likeCount,
    required this.shareCount,
    required this.viewCount,
    this.isLiked = false,
    required this.author,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      author: PostAuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'image_url': imageUrl,
        'like_count': likeCount,
        'share_count': shareCount,
        'view_count': viewCount,
        'is_liked': isLiked,
        'author': author.toJson(),
        'created_at': createdAt,
      };
}

class PostsRepository {
  final ApiClient _apiClient;

  PostsRepository(this._apiClient);

  Future<Result<List<PostModel>>> getFeed({String tab = 'for_you', int limit = 50}) async {
    return _apiClient.get<List<PostModel>>(
      '/feed',
      queryParameters: {'tab': tab, 'limit': limit},
      fromJson: (data) {
        if (data is List) {
          return data.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  /// A user's own posts (newest first) — for the profile "Posts" list.
  Future<Result<List<PostModel>>> getUserPosts(String userId, {int limit = 50}) async {
    return _apiClient.get<List<PostModel>>(
      '/users/$userId/posts',
      queryParameters: {'limit': limit},
      fromJson: (data) => data is List
          ? data.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList()
          : <PostModel>[],
    );
  }

  Future<Result<PostModel>> createPost({required String content, String? imageUrl}) async {
    return _apiClient.post<PostModel>(
      '/posts',
      data: {'content': content, if (imageUrl != null) 'image_url': imageUrl},
      fromJson: (data) => PostModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Upload a post image and get back its absolute URL (reuses POST /media).
  /// The returned URL is passed to [createPost] as `image_url`.
  Future<Result<String>> uploadImage(String filePath) {
    return _apiClient.upload<String>(
      '/media',
      filePath: filePath,
      fromJson: (d) => (d as Map<String, dynamic>)['url']?.toString() ?? '',
    );
  }

  Future<Result<PostModel>> getPostDetail(String id) async {
    return _apiClient.get<PostModel>(
      '/posts/$id',
      fromJson: (data) => PostModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<void>> likePost(String id) async {
    return _apiClient.post<void>('/posts/$id/like');
  }

  Future<Result<void>> unlikePost(String id) async {
    return _apiClient.delete<void>('/posts/$id/like');
  }

  Future<Result<void>> sharePost(String id) async {
    return _apiClient.post<void>('/posts/$id/share');
  }
}
