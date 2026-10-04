import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

class GoogleChooserScreen extends StatelessWidget {
  final ValueChanged<String> onAccountSelected;
  final VoidCallback onAddAccount;

  const GoogleChooserScreen({
    super.key,
    required this.onAccountSelected,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Row(
          children: [
            _buildGoogleMark(),
            const SizedBox(width: 10),
            Text(
              'Sign in with Google',
              style: AppTextStyles.bodyBold,
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.line, height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Choose an account to continue to ',
                style: AppTextStyles.subText,
                children: [
                  TextSpan(
                    text: 'PigeonFly',
                    style: AppTextStyles.bodyBold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account 1
            _buildAccountTile(
              initial: 'A',
              name: 'Ahmed Raza',
              email: 'ahmed@gmail.com',
              gradient: AppColors.avatarBlue,
              onTap: () => onAccountSelected('ahmed@gmail.com'),
            ),

            const Divider(color: AppColors.hair, height: 1),

            // Account 2
            _buildAccountTile(
              initial: 'S',
              name: 'Sara K',
              email: 'sara.k@gmail.com',
              gradient: AppColors.avatarPurple,
              onTap: () => onAccountSelected('sara.k@gmail.com'),
            ),

            const Divider(color: AppColors.hair, height: 1),

            // Add another account
            InkWell(
              onTap: onAddAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.soft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.sub,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Add another account',
                      style: AppTextStyles.bodyBold.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required String initial,
    required String name,
    required String email,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              text: initial,
              size: 42,
              gradient: gradient,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyBold,
                ),
                Text(
                  email,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
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
