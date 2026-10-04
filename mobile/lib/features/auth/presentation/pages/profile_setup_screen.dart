import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const ProfileSetupScreen({super.key, required this.onContinue});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String selectedLanguage = 'English';
  final TextEditingController nameController =
      TextEditingController(text: 'Ahmed Raza');
  final TextEditingController usernameController =
      TextEditingController(text: 'ahmed_loft');

  final languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ur', 'label': 'اردو'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'ar', 'label': 'العربية'},
  ];

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
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: AppColors.brand,
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
              AppButton(
                text: 'Continue',
                onPressed: widget.onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
