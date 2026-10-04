import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  int _selectedIndex = 0; // 0 = English, 1 = Urdu, 2 = Hindi, 3 = Arabic

  final List<Map<String, String>> _languages = [
    {'code': 'EN', 'name': 'English', 'native': '', 'isRtl': 'false'},
    {'code': 'اُ', 'name': 'Urdu', 'native': 'اردو · Urdu', 'isRtl': 'true'},
    {'code': 'हि', 'name': 'Hindi', 'native': 'हिन्दी · Hindi', 'isRtl': 'false'},
    {'code': 'ع', 'name': 'Arabic', 'native': 'العربية · Arabic', 'isRtl': 'true'},
  ];

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
        title: Text('Language', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          Text(
            'Choose your app language. Urdu & Arabic display right-to-left.',
            style: AppTextStyles.body.copyWith(color: AppColors.sub, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._languages.asMap().entries.map((entry) {
            final idx = entry.key;
            final lang = entry.value;
            final isSelected = _selectedIndex == idx;
            final isRtl = lang['isRtl'] == 'true';

            return InkWell(
              onTap: () => setState(() => _selectedIndex = idx),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand50 : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.brand : AppColors.line,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: AppShadows.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : AppColors.soft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        lang['code']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      lang['native']!.isNotEmpty ? lang['native']! : lang['name']!,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isSelected ? AppColors.brand : AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    if (isRtl) ...[
                      Text('RTL', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut)),
                      const SizedBox(width: 8),
                    ],
                    if (isSelected)
                      const Icon(Icons.check_rounded, color: AppColors.brand, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
