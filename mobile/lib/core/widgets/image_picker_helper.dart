import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows an iOS/Material styled bottom sheet with options:
  /// - Take Photo (Camera)
  /// - Choose from Gallery (Photo Library)
  static Future<File?> showImageSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select Image Source', style: AppTextStyles.cardTitle),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.brand),
                  ),
                  title: Text('Take Photo', style: AppTextStyles.bodyBold),
                  subtitle: Text('Open device camera', style: AppTextStyles.caption),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                const Divider(height: 1, color: AppColors.line),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.ink2),
                  ),
                  title: Text('Choose from Gallery', style: AppTextStyles.bodyBold),
                  subtitle: Text('Select from photos', style: AppTextStyles.caption),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        return File(picked.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Direct camera capture
  static Future<File?> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
    return null;
  }

  /// Pick a video from the gallery (capped duration keeps uploads small).
  static Future<File?> pickVideoFromGallery() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
    return null;
  }

  /// Direct gallery picker
  static Future<File?> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
    return null;
  }
}
