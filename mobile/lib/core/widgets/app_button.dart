import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, ghost, dark, soft, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final dynamic icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;
    List<BoxShadow> shadows = [];

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.brand;
        fg = Colors.white;
        shadows = AppShadows.brandButton;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.white;
        fg = AppColors.ink;
        border = const BorderSide(color: AppColors.line, width: 1.5);
        shadows = AppShadows.xs;
        break;
      case AppButtonVariant.dark:
        bg = AppColors.ink;
        fg = Colors.white;
        shadows = AppShadows.sm;
        break;
      case AppButtonVariant.soft:
        bg = AppColors.brand50;
        fg = AppColors.brand;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        shadows = AppShadows.dangerButton;
        break;
    }

    final buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          if (icon is IconData)
            Icon(icon as IconData, size: 18, color: fg)
          else if (icon is Widget)
            icon as Widget,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: AppTextStyles.buttonText.copyWith(color: fg),
        ),
      ],
    );

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: buttonChild),
          ),
        ),
      ),
    );
  }
}
