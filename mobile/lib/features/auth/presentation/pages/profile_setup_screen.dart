import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/image_picker_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const ProfileSetupScreen({super.key, required this.onContinue});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _selectedImage;
  String selectedLanguage = 'English';
  late final TextEditingController nameController;
  late final TextEditingController usernameController;

  final languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ur', 'label': 'اردو'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'ar', 'label': 'العربية'},
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final initialName = authState.name ?? '';
    // Generate suggested username from name or email (e.g. ahmed_raza)
    String suggestedUsername = '';
    if (initialName.isNotEmpty) {
      suggestedUsername = initialName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
    } else if (authState.email != null && authState.email!.isNotEmpty) {
      suggestedUsername = authState.email!.split('@').first.toLowerCase();
    }

    nameController = TextEditingController(text: initialName);
    usernameController = TextEditingController(text: suggestedUsername);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(
          'Set up your profile',
          style: AppTextStyles.sectionTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo picker circle
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final image = await ImagePickerHelper.showImageSourceSheet(context);
                            if (image != null) {
                              setState(() => _selectedImage = image);
                            }
                          },
                          borderRadius: BorderRadius.circular(46),
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.soft,
                              border: Border.all(
                                color: AppColors.brand100,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 32,
                                      color: AppColors.brand,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      Text(
                        'NAME',
                        style: AppTextStyles.overline,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: AppTextStyles.bodyBold,
                        decoration: const InputDecoration(
                          hintText: 'Your full name',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Username field
                      Text(
                        'USERNAME',
                        style: AppTextStyles.overline,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: usernameController,
                        style: AppTextStyles.bodyBold,
                        decoration: const InputDecoration(
                          prefixText: '@',
                          hintText: 'username',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Language chips
                      Text(
                        'LANGUAGE',
                        style: AppTextStyles.overline,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: languages.map((lang) {
                          final isSelected = selectedLanguage == lang['label'];
                          return ChoiceChip(
                            label: Text(
                              lang['label']!,
                              style: AppTextStyles.subText.copyWith(
                                color: isSelected ? Colors.white : AppColors.ink2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.brand,
                            backgroundColor: AppColors.soft,
                            side: BorderSide(
                              color: isSelected ? AppColors.brand : AppColors.line,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (val) {
                              setState(() {
                                selectedLanguage = lang['label']!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Continue button
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.authenticated) {
                    widget.onContinue();
                  } else if (state.status == AuthStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage ?? 'Setup failed')),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state.status == AuthStatus.loading;
                  return AppButton(
                    text: isLoading ? 'Saving…' : 'Continue',
                    onPressed: isLoading
                        ? () {}
                        : () {
                            final name = nameController.text.trim();
                            final rawUser = usernameController.text.trim();
                            final username = rawUser.startsWith('@')
                                ? rawUser.substring(1)
                                : rawUser;

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your name')),
                              );
                              return;
                            }
                            if (username.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a username')),
                              );
                              return;
                            }

                            final selectedEntry = languages.firstWhere(
                              (l) => l['label'] == selectedLanguage,
                              orElse: () => {'code': 'en'},
                            );

                            context.read<AuthBloc>().add(
                                  AuthProfileSubmittedEvent(
                                    name: name,
                                    username: username,
                                    language: selectedEntry['code'] ?? 'en',
                                  ),
                                );
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
