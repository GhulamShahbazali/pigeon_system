import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/image_picker_helper.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserRepository _userRepo = sl<UserRepository>();
  File? _profileImage;
  String? _existingPhotoUrl;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await _userRepo.getMyProfile();
    if (!mounted) return;
    if (result.isSuccess) {
      final user = (result as dynamic).data as UserProfileModel;
      _nameController.text = user.displayName;
      _usernameController.text = '@${user.username}';
      _bioController.text = user.bio ?? '';
      _cityController.text = user.city ?? '';
      _existingPhotoUrl = user.photoUrl;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final rawName = _nameController.text.trim();
    // Username may be shown/typed with a leading "@"; the API wants it without.
    final rawUsername =
        _usernameController.text.trim().replaceFirst(RegExp(r'^@+'), '');
    final rawBio = _bioController.text.trim();
    final rawCity = _cityController.text.trim();

    // If the user picked a new photo, upload it first and save its URL on the
    // profile. Without this the picked image was silently discarded (the reason
    // the avatar never updated).
    String? photoUrl;
    if (_profileImage != null) {
      final uploadRes = await _userRepo.uploadProfilePhoto(_profileImage!.path);
      if (!mounted) return;
      if (uploadRes.isSuccess) {
        final url = (uploadRes as dynamic).data as String;
        if (url.isNotEmpty) photoUrl = url;
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((uploadRes as dynamic).message ?? 'Photo upload failed')),
        );
        return;
      }
    }

    final result = await _userRepo.updateMyProfile(
      displayName: rawName.isNotEmpty ? rawName : null,
      username: rawUsername.isNotEmpty ? rawUsername : null,
      bio: rawBio.isNotEmpty ? rawBio : null,
      city: rawCity.isNotEmpty ? rawCity : null,
      photoUrl: photoUrl,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).profileUpdated)),
      );
      Navigator.of(context).pop(true);
    } else {
      final err = (result as dynamic).message ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Widget _avatarInitial() {
    final name = _nameController.text.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
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
        title: Text(s.editProfile, style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                  )
                : Text(s.save, style: AppTextStyles.bodyBold.copyWith(color: AppColors.brand)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Avatar picker
            Center(
              child: InkWell(
                onTap: () async {
                  final file = await ImagePickerHelper.showImageSourceSheet(context);
                  if (file != null) {
                    setState(() => _profileImage = file);
                  }
                },
                borderRadius: BorderRadius.circular(42),
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.avatarBlue,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : (_existingPhotoUrl != null && _existingPhotoUrl!.trim().isNotEmpty)
                              ? Image.network(
                                  _existingPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarInitial(),
                                )
                              : _avatarInitial(),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _Field(label: s.nameLabel, controller: _nameController),
            const SizedBox(height: 18),
            _Field(label: s.usernameLabel, controller: _usernameController),
            const SizedBox(height: 18),
            _Field(label: s.bioLabel, controller: _bioController, hint: s.bioHint, maxLines: 3),
            const SizedBox(height: 18),
            _Field(label: s.cityLabel, controller: _cityController),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelUppercase),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyBold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
            fillColor: AppColors.card,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
