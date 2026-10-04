import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EditPigeonSheet extends StatelessWidget {
  final String pigeonName;
  final String landingTime;
  final String average;
  final Function(String name, String time)? onSave;
  final VoidCallback? onDelete;

  const EditPigeonSheet({
    super.key,
    this.pigeonName = 'Shaheen',
    this.landingTime = '12:40 PM',
    this.average = '12:40',
    this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    String pigeonName = 'Shaheen',
    String landingTime = '12:40 PM',
    String average = '12:40',
    Function(String name, String time)? onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPigeonSheet(
        pigeonName: pigeonName,
        landingTime: landingTime,
        average: average,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: pigeonName);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit pigeon', textAlign: TextAlign.center, style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Text('Pigeon name', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: AppTextStyles.bodyBold,
              decoration: InputDecoration(
                fillColor: AppColors.card,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Landing time', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.mut),
                  const SizedBox(width: 12),
                  Text(landingTime, style: AppTextStyles.bodyBold),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Average (auto)', style: AppTextStyles.body.copyWith(color: AppColors.sub, fontWeight: FontWeight.w600)),
                  Text(average, style: AppTextStyles.h4.copyWith(color: AppColors.brand)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete?.call();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 50,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.danger50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSave?.call(nameController.text.trim(), landingTime);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Save pigeon', style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
