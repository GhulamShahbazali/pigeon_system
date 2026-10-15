import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/locale_cubit.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  final List<Map<String, dynamic>> _languages = const [
    {'lang': AppLanguage.english, 'icon': 'EN'},
    {'lang': AppLanguage.urdu, 'icon': 'اُ'},
    {'lang': AppLanguage.hindi, 'icon': 'हि'},
    {'lang': AppLanguage.arabic, 'icon': 'ع'},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, AppLanguage>(
      builder: (context, currentLang) {
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
              ..._languages.map((item) {
                final lang = item['lang'] as AppLanguage;
                final icon = item['icon'] as String;
                final isSelected = currentLang == lang;

                return InkWell(
                  onTap: () {
                    context.read<LocaleCubit>().setLanguage(lang);
                  },
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
                            icon,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          lang.nativeName,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: isSelected ? AppColors.brand : AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        if (lang.isRtl) ...[
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
      },
    );
  }
}
