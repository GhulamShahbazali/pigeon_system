import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/result/result.dart';
import '../../data/tournaments_repository.dart';
import 'add_participant_screen.dart';

class TournamentParticipantsScreen extends StatefulWidget {
  final String? tournamentId;
  final Map<String, dynamic>? tournamentData;

  const TournamentParticipantsScreen({
    super.key,
    this.tournamentId,
    this.tournamentData,
  });

  @override
  State<TournamentParticipantsScreen> createState() => _TournamentParticipantsScreenState();
}

class _TournamentParticipantsScreenState extends State<TournamentParticipantsScreen> {
  final List<Map<String, dynamic>> _participants = [];
  bool _isCreating = false;
  final TournamentsRepository _tournamentsRepo = sl<TournamentsRepository>();

  int get _maxPigeons => (widget.tournamentData?['pigeon_count'] as int?) ?? 20;

  Future<void> _handleCreateTournament() async {
    if (widget.tournamentData == null && (widget.tournamentId == null || widget.tournamentId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing tournament details.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      String createdId = widget.tournamentId ?? '';

      if (createdId.isEmpty && widget.tournamentData != null) {
        final res = await _tournamentsRepo.createTournament(widget.tournamentData!);
        if (res is FailureResult<Map<String, dynamic>>) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.message)),
            );
          }
          setState(() => _isCreating = false);
          return;
        }
        final data = (res as Success<Map<String, dynamic>>).data;
        createdId = (data['id'] ?? data['data']?['id'] ?? '').toString();
      }

      if (createdId.isNotEmpty) {
        for (final p in _participants) {
          await _tournamentsRepo.addParticipant(createdId, {
            'name': p['name'],
            if (p['phone'] != null && (p['phone'] as String).isNotEmpty) 'phone': p['phone'],
            if (p['contact_no'] != null && (p['contact_no'] as String).isNotEmpty) 'contact_no': p['contact_no'],
            if (p['address'] != null && (p['address'] as String).isNotEmpty) 'address': p['address'],
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament created successfully!')),
          );
          context.pushReplacement('/tournaments/detail/$createdId?isOwner=true');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to retrieve created tournament ID')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
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
                '${_participants.length} / $_maxPigeons',
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
                                  'name': name,
                                  'phone': phone.isNotEmpty ? phone : null,
                                  'contact_no': contact.isNotEmpty ? contact : null,
                                  'address': address.isNotEmpty ? address : null,
                                  'initial': name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                  'meta': phone.isNotEmpty
                                      ? '$phone · $address'
                                      : (address.isNotEmpty ? address : 'Contact optional'),
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
                        '${_maxPigeons - _participants.length > 0 ? _maxPigeons - _participants.length : 0} left',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.mut),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_participants.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_add_outlined,
                            size: 48,
                            color: AppColors.sub.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No participants added yet',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Add participant" above to add flyers to this tournament.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
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
                              text: (p['initial'] as String?) ?? 'P',
                              size: 42,
                              gradient: idx.isEven ? AppColors.avatarBlue : AppColors.avatarPurple,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((p['name'] as String?) ?? '', style: AppTextStyles.bodyBold),
                                  const SizedBox(height: 2),
                                  Text(
                                    (p['meta'] as String?) ?? '',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => AddParticipantScreen(
                                      initialName: p['name'] as String?,
                                      initialPhone: p['phone'] as String?,
                                      initialContact: p['contact_no'] as String?,
                                      initialAddress: p['address'] as String?,
                                      onSave: (name, phoneVal, contactVal, addressVal) {
                                        setState(() {
                                          _participants[idx] = {
                                            'name': name,
                                            'phone': phoneVal.isNotEmpty ? phoneVal : null,
                                            'contact_no': contactVal.isNotEmpty ? contactVal : null,
                                            'address': addressVal.isNotEmpty ? addressVal : null,
                                            'initial': name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                            'meta': phoneVal.isNotEmpty
                                                ? '$phoneVal · $addressVal'
                                                : (addressVal.isNotEmpty ? addressVal : 'Contact optional'),
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
                isLoading: _isCreating,
                isFullWidth: true,
                onPressed: _isCreating ? null : _handleCreateTournament,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
