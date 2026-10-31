import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/image_picker_helper.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../settings/data/user_repository.dart';
import '../../data/posts_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostsRepository _postsRepo = sl<PostsRepository>();
  final UserRepository _userRepo = sl<UserRepository>();
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isPublishing = false;

  // Real author (loaded from the signed-in user's profile), not a placeholder.
  String _authorName = 'You';
  String? _authorPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadAuthor();
  }

  Future<void> _loadAuthor() async {
    final res = await _userRepo.getMyProfile();
    if (!mounted || !res.isSuccess) return;
    final me = (res as dynamic).data as UserProfileModel;
    setState(() {
      _authorName = me.displayName;
      _authorPhotoUrl = me.photoUrl;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePickerHelper.showImageSourceSheet(context);
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).writeSomethingToPost)),
      );
      return;
    }
    setState(() => _isPublishing = true);

    // Upload the picked image first (if any) and attach its URL to the post.
    String? imageUrl;
    if (_selectedImage != null) {
      final up = await _postsRepo.uploadImage(_selectedImage!.path);
      if (!mounted) return;
      if (up.isSuccess) {
        final url = (up as dynamic).data as String;
        if (url.isNotEmpty) imageUrl = url;
      } else {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((up as dynamic).message ?? 'Image upload failed')),
        );
        return;
      }
    }

    final res = await _postsRepo.createPost(content: content, imageUrl: imageUrl);
    if (!mounted) return;
    setState(() => _isPublishing = false);
    if (res.isSuccess) {
      Navigator.of(context).pop(true); // caller reloads so the new post shows
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((res as dynamic).message ?? 'Could not publish post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
        title: Text(s.newPostTitle, style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AppButton(
                text: s.publish,
                isFullWidth: false,
                height: 38,
                isLoading: _isPublishing,
                onPressed: _publish,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Row & Visibility Pill
                    Row(
                      children: [
                        AppAvatar(
                          name: _authorName,
                          imageUrl: _authorPhotoUrl,
                          size: 42,
                          gradient: AppColors.avatarBlue,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_authorName, style: AppTextStyles.bodyBold),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.soft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.brand),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.publicLabel,
                                    style: AppTextStyles.captionBold.copyWith(color: AppColors.ink2, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content Field
                    TextField(
                      controller: _contentController,
                      maxLines: 6,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: s.shareLoftHint,
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Photo Area
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.soft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, size: 24, color: AppColors.brand),
                              const SizedBox(width: 8),
                              Text(s.addPhoto, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: _isPublishing ? s.publishing : s.publishPost,
                isFullWidth: true,
                isLoading: _isPublishing,
                onPressed: _publish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
