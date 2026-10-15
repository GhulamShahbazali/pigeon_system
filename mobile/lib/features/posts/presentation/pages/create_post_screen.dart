import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/image_picker_helper.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;

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
        title: Text('New Post', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AppButton(
                text: 'Publish',
                onPressed: () => Navigator.of(context).pop(),
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
                        const AppAvatar(
                          text: 'A',
                          size: 42,
                          gradient: AppColors.avatarBlue,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ahmed Loft', style: AppTextStyles.bodyBold),
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
                                    'Public',
                                    style: AppTextStyles.captionBold.copyWith(color: AppColors.ink2, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.mut),
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
                        hintText: 'Share something about your loft…',
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
                              Text('Add photo', style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
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
                text: 'Publish post',
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
