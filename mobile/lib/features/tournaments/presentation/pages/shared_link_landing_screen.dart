import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class SharedLinkLandingScreen extends StatelessWidget {
  const SharedLinkLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soft,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 14, color: AppColors.sub),
            const SizedBox(width: 6),
            Text('pigeonfly.app', style: AppTextStyles.captionBold.copyWith(color: AppColors.sub)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Tournament Card Preview
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppShadows.xs,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(gradient: AppColors.duskMesh),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE · Day 2',
                                  style: AppTextStyles.captionBold.copyWith(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'City Loft Championship',
                                style: AppTextStyles.h4.copyWith(color: Colors.white),
                              ),
                              Text(
                                'by Ahmed Loft · 20 pigeons',
                                style: AppTextStyles.caption.copyWith(color: AppColors.white90),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.mut),
                          const SizedBox(width: 6),
                          Text('3 days · Alternate', style: AppTextStyles.caption.copyWith(color: AppColors.sub)),
                          const Spacer(),
                          Text('Avg 14:32', style: AppTextStyles.captionBold.copyWith(color: AppColors.brand)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Open this tournament in PigeonFly',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Open in app',
                icon: Icons.flight_takeoff_rounded,
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
              Text(
                "Don't have the app?",
                style: AppTextStyles.captionBold.copyWith(color: AppColors.mut),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'App Store',
                      icon: Icons.apple_rounded,
                      variant: AppButtonVariant.dark,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Google Play',
                      icon: Icons.play_arrow_rounded,
                      variant: AppButtonVariant.dark,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'After installing, this tournament opens automatically.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.mut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
