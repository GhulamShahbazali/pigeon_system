import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pigeon_watermark.dart';
import '../widgets/post_options_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final String authorName;
  final String timeAgo;
  final String content;
  final int likes;
  final int shares;
  final String views;

  const PostDetailScreen({
    super.key,
    this.authorName = 'Ahmed Loft',
    this.timeAgo = '2h ago · Public',
    this.content = 'Morning kit flew beautifully today. 18 birds, all back by noon. Proud of the young Shaheen — first one home.',
    this.likes = 214,
    this.shares = 12,
    this.views = '1.3k',
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  late int _likeCount;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
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
                  const AppAvatar(
                    text: 'A',
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
                        Text(widget.timeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
                      ],
                    ),
                  ),
                  AppButton(
                    text: _isFollowing ? 'Following' : 'Follow',
                    variant: _isFollowing ? AppButtonVariant.soft : AppButtonVariant.primary,
                    onPressed: () => setState(() => _isFollowing = !_isFollowing),
                  ),
                ],
              ),
            ),

            // Content text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                widget.content,
                style: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.45),
              ),
            ),

            // Media Preview
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.heroMeshSky,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: PigeonWatermark(
                  width: 108,
                  height: 108,
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
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                        _likeCount += _isLiked ? 1 : -1;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: _isLiked ? AppColors.danger : AppColors.sub,
                        ),
                        const SizedBox(width: 8),
                        Text('$_likeCount', style: AppTextStyles.bodyBold.copyWith(color: _isLiked ? AppColors.danger : AppColors.sub)),
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
