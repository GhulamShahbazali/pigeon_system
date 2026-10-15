import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/local_storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/posts_repository.dart';
import '../widgets/post_card.dart';

/// A user's posts (own profile "My Posts", or another user's "Posts").
class MyPostsScreen extends StatefulWidget {
  final String userId;
  final String title;

  const MyPostsScreen({super.key, required this.userId, this.title = 'My Posts'});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final PostsRepository _repo = sl<PostsRepository>();
  final SecureStorageService _storage = sl<SecureStorageService>();
  List<PostModel> _posts = [];
  final Set<String> _liked = {};
  final Map<String, int> _likeCounts = {};
  bool _loading = true;
  bool _isMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _resolveIsMe();
  }

  /// Only the owner of this feed may create a post here, so compare the viewed
  /// userId against the signed-in user's id (decoded from the session JWT).
  Future<void> _resolveIsMe() async {
    final myId = await _storage.getUserId();
    if (mounted) setState(() => _isMe = myId != null && myId == widget.userId);
  }

  Future<void> _createPost() async {
    await context.push('/posts/create');
    if (mounted) _load(); // reflect the newly created post on return
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getUserPosts(widget.userId);
    if (!mounted) return;
    res.when(
      success: (data) => setState(() {
        _posts = data;
        for (final p in data) {
          if (p.isLiked) _liked.add(p.id);
          _likeCounts[p.id] = p.likeCount;
        }
        _loading = false;
      }),
      failure: (m, __) => setState(() {
        _error = m;
        _loading = false;
      }),
    );
  }

  Future<void> _toggleLike(PostModel p) async {
    final liked = _liked.contains(p.id);
    setState(() {
      if (liked) {
        _liked.remove(p.id);
        _likeCounts[p.id] = (_likeCounts[p.id] ?? p.likeCount) - 1;
      } else {
        _liked.add(p.id);
        _likeCounts[p.id] = (_likeCounts[p.id] ?? p.likeCount) + 1;
      }
    });
    final r = liked ? await _repo.unlikePost(p.id) : await _repo.likePost(p.id);
    if (r.isFailure && mounted) {
      setState(() {
        if (liked) {
          _liked.add(p.id);
          _likeCounts[p.id] = (_likeCounts[p.id] ?? p.likeCount) + 1;
        } else {
          _liked.remove(p.id);
          _likeCounts[p.id] = (_likeCounts[p.id] ?? p.likeCount) - 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: AppTextStyles.screenTitle),
      ),
      floatingActionButton: _isMe
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              onPressed: _createPost,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.of(context).newPost, style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _buildBody(AppStrings.of(context)),
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body)));
    }
    if (_posts.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.dynamic_feed_rounded, size: 54, color: AppColors.muted),
        const SizedBox(height: 12),
        Center(child: Text(s.noPostsYet, style: AppTextStyles.cardTitle)),
        if (_isMe) ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(s.createFirstPost,
                  style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ]);
    }
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.hair, height: 8, thickness: 8),
      itemBuilder: (context, i) {
        final p = _posts[i];
        return PostCard(
          authorName: p.author.displayName,
          avatarUrl: p.author.photoUrl,
          timeAgo: 'Recently',
          content: p.content,
          imageUrl: p.imageUrl,
          likes: _likeCounts[p.id] ?? p.likeCount,
          shares: p.shareCount,
          views: p.viewCount.toString(),
          isLiked: _liked.contains(p.id),
          onFollowPressed: () {},
          onLikePressed: () => _toggleLike(p),
          onTap: () => context.push('/posts/detail', extra: p),
        );
      },
    );
  }
}
