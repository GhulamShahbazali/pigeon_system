import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class AddParticipantScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialContact;
  final String? initialAddress;
  final Function(String name, String phone, String contact, String address)? onSave;

  const AddParticipantScreen({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialContact,
    this.initialAddress,
    this.onSave,
  });

  @override
  State<AddParticipantScreen> createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _contactController = TextEditingController(text: widget.initialContact ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.initialName != null ? 'Edit participant' : 'Add participant', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Photo picker
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: AppColors.soft,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.ink2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photo',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.brand),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Name
                    _FormField(
                      label: 'Name *',
                      child: TextField(
                        controller: _nameController,
                        style: AppTextStyles.bodyBold,
                        decoration: _inputDecoration('Enter participant name'),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Contact no
                    _FormField(
                      label: 'Contact no · optional',
                      child: TextField(
                        controller: _contactController,
                        style: AppTextStyles.bodyBold,
                        decoration: _inputDecoration(
                          'e.g. WhatsApp number',
                          prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.mut),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Phone
                    _FormField(
                      label: 'Phone · optional',
                      child: TextField(
                        controller: _phoneController,
                        style: AppTextStyles.bodyBold,
                        decoration: _inputDecoration(
                          'Phone number',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.mut),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Address
                    _FormField(
                      label: 'Address · optional',
                      child: TextField(
                        controller: _addressController,
                        style: AppTextStyles.bodyBold,
                        decoration: _inputDecoration(
                          'City / loft address',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.mut),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: 'Save participant',
                isFullWidth: true,
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isNotEmpty) {
                    widget.onSave?.call(
                      name,
                      _phoneController.text.trim(),
                      _contactController.text.trim(),
                      _addressController.text.trim(),
                    );
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
      prefixIcon: prefixIcon,
      fillColor: AppColors.card,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelUppercase),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
