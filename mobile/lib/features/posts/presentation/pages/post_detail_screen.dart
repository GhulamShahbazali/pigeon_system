import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../../data/posts_repository.dart';
import '../widgets/post_options_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final String? postId;
  final String authorName;
  final String authorHandle;
  final String? authorPhotoUrl;
  final String? authorId;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int likes;
  final int shares;
  final String views;
  final bool isLiked;

  const PostDetailScreen({
    super.key,
    this.postId,
    this.authorName = 'Flyer',
    this.authorHandle = '@flyer',
    this.authorPhotoUrl,
    this.authorId,
    this.timeAgo = 'Recently',
    this.content = '',
    this.imageUrl,
    this.likes = 0,
    this.shares = 0,
    this.views = '0',
    this.isLiked = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  bool _isFollowing = false;
  final PostsRepository _postsRepo = sl<PostsRepository>();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likes;
  }

  void _openAuthorProfile() {
    final id = widget.authorId;
    if (id != null && id.isNotEmpty) context.push('/user/$id');
  }

  void _toggleLike() {
    final nextState = !_isLiked;
    setState(() {
      _isLiked = nextState;
      _likeCount += nextState ? 1 : -1;
    });

    if (widget.postId != null && widget.postId!.isNotEmpty) {
      if (nextState) {
        _postsRepo.likePost(widget.postId!);
      } else {
        _postsRepo.unlikePost(widget.postId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Post', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 24, color: AppColors.ink2),
            onPressed: () {
              PostOptionsSheet.show(
                context,
                authorName: widget.authorName,
                onHide: () => Navigator.of(context).pop(),
                onUnfollow: () => setState(() => _isFollowing = false),
                onCopyLink: () {},
                onReport: () {},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _openAuthorProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          AppAvatar(
                            text: widget.authorName,
                            imageUrl: widget.authorPhotoUrl,
                            size: 42,
                            gradient: AppColors.avatarBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.authorName, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.authorHandle} · ${widget.timeAgo}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: _isFollowing ? 'Following' : 'Follow',
                    variant: _isFollowing ? AppButtonVariant.soft : AppButtonVariant.primary,
                    isFullWidth: false,
                    height: 38,
                    onPressed: () => setState(() => _isFollowing = !_isFollowing),
                  ),
                ],
              ),
            ),

            // Content text
            if (widget.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  widget.content,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.45),
                ),
              ),

            // Media Preview — show actual image if available
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.soft,
                ),
                child: Image.network(
                  widget.imageUrl!,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 240,
                          width: double.infinity,
                          decoration: const BoxDecoration(gradient: AppColors.heroMeshSky),
                          child: const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            ),
                          ),
                        ),
                  errorBuilder: (context, error, stack) => Container(
                    height: 240,
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: AppColors.heroMeshSky),
                    child: const Center(
                      child: PigeonWatermark(width: 108, height: 108, color: Color(0xE6FFFFFF)),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.heroMeshSky,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: PigeonWatermark(
                    width: 90,
                    height: 90,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ),

            // Action counts row
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.hair),
                  bottom: BorderSide(color: AppColors.hair),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: _isLiked ? AppColors.danger : AppColors.sub,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_likeCount',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: _isLiked ? AppColors.danger : AppColors.sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.share_outlined, size: 20, color: AppColors.sub),
                      const SizedBox(width: 8),
                      Text('${widget.shares}', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 20, color: AppColors.mut),
                      const SizedBox(width: 8),
                      Text(widget.views, style: AppTextStyles.bodyBold.copyWith(color: AppColors.mut)),
                    ],
                  ),
                ],
              ),
            ),

            // Real-time live indicator banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.ok50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Likes & views update in real time',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.ok),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
