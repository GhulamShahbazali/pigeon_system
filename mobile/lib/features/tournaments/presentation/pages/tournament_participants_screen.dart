import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import 'add_participant_screen.dart';

class TournamentParticipantsScreen extends StatefulWidget {
  const TournamentParticipantsScreen({super.key});

  @override
  State<TournamentParticipantsScreen> createState() => _TournamentParticipantsScreenState();
}

class _TournamentParticipantsScreenState extends State<TournamentParticipantsScreen> {
  final List<Map<String, String>> _participants = [
    {
      'initial': 'B',
      'name': 'Bilal Raza',
      'meta': '0300-1234567 · Loft St.',
    },
    {
      'initial': 'K',
      'name': 'Kashif Ali',
      'meta': 'Contact optional',
    },
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
        title: Text('Participants', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_participants.length} / 20',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  AppButton(
                    text: 'Add participant',
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.soft,
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AddParticipantScreen(
                            onSave: (name, phone, contact, address) {
                              setState(() {
                                _participants.add({
                                  'initial': name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                  'name': name,
                                  'meta': phone.isNotEmpty ? '$phone · $address' : 'Contact optional',
                                });
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Added · ${_participants.length}', style: AppTextStyles.labelUppercase),
                      Text(
                        '${20 - _participants.length} left',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.mut),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._participants.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.xs,
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            text: p['initial']!,
                            size: 42,
                            gradient: idx.isEven ? AppColors.avatarBlue : AppColors.avatarPurple,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name']!, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  p['meta']!,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final parts = (p['meta'] ?? '').split(' · ');
                              final phone = parts.isNotEmpty ? parts[0] : '';
                              final addr = parts.length > 1 ? parts[1] : '';
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => AddParticipantScreen(
                                    initialName: p['name'],
                                    initialPhone: phone,
                                    initialAddress: addr,
                                    onSave: (name, phoneVal, contactVal, addressVal) {
                                      setState(() {
                                        _participants[idx] = {
                                          'initial': name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                          'name': name,
                                          'meta': phoneVal.isNotEmpty ? '$phoneVal · $addressVal' : 'Contact optional',
                                        };
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.soft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _participants.removeAt(idx);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.danger50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: 'Create tournament',
                isFullWidth: true,
                onPressed: () {
                  context.pushReplacement('/tournaments/detail/city-loft?isOwner=true');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
