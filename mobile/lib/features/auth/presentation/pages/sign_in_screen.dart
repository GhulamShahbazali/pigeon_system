import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pigeon_watermark.dart';

class SignInScreen extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const SignInScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Hero with mesh sky gradient and dove watermark
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroMeshSky,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dove watermark: right -26px, top 44px, width 230
                  const Positioned(
                    top: 36,
                    right: -24,
                    child: PigeonWatermark(
                      width: 240,
                      height: 240,
                      color: Color(0x2EFFFFFF),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.white14,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: AppColors.white28,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: PigeonWatermark(
                                width: 30,
                                height: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Fly higher,\ntogether.',
                            style: AppTextStyles.heroTitle,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Run tournaments, follow the flights live, and share your loft — anywhere.',
                            style: AppTextStyles.subtitleWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with sign in buttons
          Container(
            width: double.infinity,
            transform: Matrix4.translationValues(0, -28, 0),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign in to continue',
                    style: AppTextStyles.subText,
                  ),
                  const SizedBox(height: 18),

                  // Google button
                  InkWell(
                    onTap: onGoogleSignIn,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.line, width: 1.5),
                        boxShadow: AppShadows.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleMark(),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Apple button
                  InkWell(
                    onTap: onAppleSignIn,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apple, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Apple',
                            style: AppTextStyles.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By continuing you agree to our ',
                      style: AppTextStyles.caption,
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMark() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFEA4335),
            Color(0xFFFBBC05),
            Color(0xFF34A853),
            Color(0xFF4285F4),
            Color(0xFFEA4335),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
