import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGoToTournaments;
  final VoidCallback onCreateTournament;

  const WelcomeScreen({
    super.key,
    required this.onGoToTournaments,
    required this.onCreateTournament,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: AppColors.ok50,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 46,
                          color: AppColors.ok,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome, Ahmed!',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your loft is ready. Explore tournaments or create your own.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.sub,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  AppButton(
                    text: 'Go to Tournaments',
                    onPressed: onGoToTournaments,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Create my first tournament',
                    variant: AppButtonVariant.ghost,
                    icon: const Icon(
                      Icons.emoji_events_outlined,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    onPressed: onCreateTournament,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
