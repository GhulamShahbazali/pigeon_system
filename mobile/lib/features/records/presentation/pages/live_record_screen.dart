import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/edit_pigeon_sheet.dart';

class LiveRecordScreen extends StatefulWidget {
  final bool isOwner;
  final String loftName;

  const LiveRecordScreen({
    super.key,
    this.isOwner = false,
    this.loftName = "Ahmed's loft",
  });

  @override
  State<LiveRecordScreen> createState() => _LiveRecordScreenState();
}

class _LiveRecordScreenState extends State<LiveRecordScreen> {
  bool _isLiked = false;
  int _likeCount = 54;

  final List<Map<String, dynamic>> _pigeons = [
    {'name': 'Shaheen', 'landing': '12:40 PM', 'avg': '12:40', 'isNew': false},
    {'name': 'Toofan', 'landing': '01:05 PM', 'avg': '13:05', 'isNew': false},
    {'name': 'Noori', 'landing': '01:12 PM', 'avg': '13:12', 'isNew': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          children: [
            Text(widget.loftName, style: AppTextStyles.h4),
            Text('Today · 16 Oct', style: AppTextStyles.caption.copyWith(color: AppColors.mut)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.ink2),
              onPressed: () {},
            )
          else
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? AppColors.danger : AppColors.ink2,
              ),
              onPressed: () {
                setState(() {
                  _isLiked = !_isLiked;
                  _likeCount += _isLiked ? 1 : -1;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Status bar
                    if (widget.isOwner)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E3A26), Color(0xFF12B76A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("You're live", style: AppTextStyles.bodyBold.copyWith(color: Colors.white)),
                                  Text('Followers are watching · 870 viewers', style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white28,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stop_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('End', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: AppColors.ok50,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.ok,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE · updating now',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.ok),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Content: Table for watcher vs Owner edit list
                    if (!widget.isOwner) ...[
                      // Table header
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Pigeon', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                            Expanded(flex: 3, child: Text('Landed', style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                            Expanded(flex: 2, child: Text('Avg', textAlign: TextAlign.right, style: AppTextStyles.captionBold.copyWith(color: AppColors.mut))),
                          ],
                        ),
                      ),
                      // Table rows
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                          border: Border(
                            left: BorderSide(color: AppColors.line),
                            right: BorderSide(color: AppColors.line),
                            bottom: BorderSide(color: AppColors.line),
                          ),
                        ),
                        child: Column(
                          children: _pigeons.map((p) {
                            final isNew = p['isNew'] as bool;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isNew ? AppColors.ok50 : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(p['name'] as String, style: AppTextStyles.bodyBold)),
                                  Expanded(flex: 3, child: Text(p['landing'] as String, style: AppTextStyles.body)),
                                  Expanded(flex: 2, child: Text(p['avg'] as String, textAlign: TextAlign.right, style: AppTextStyles.bodyBold.copyWith(color: isNew ? AppColors.ok : AppColors.brand))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      // Owner live edit rows
                      ..._pigeons.map((p) {
                        final isNew = p['isNew'] as bool;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isNew ? AppColors.ok50 : AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isNew ? AppColors.ok : AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['name'] as String, style: AppTextStyles.bodyBold),
                                    Text(
                                      isNew ? 'Landed ${p['landing']} · just now' : 'Landed ${p['landing']}',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                p['avg'] as String,
                                style: AppTextStyles.bodyBold.copyWith(color: isNew ? AppColors.ok : AppColors.brand),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  EditPigeonSheet.show(
                                    context,
                                    pigeonName: p['name'] as String,
                                    landingTime: p['landing'] as String,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Add landing button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: AppButton(
                          text: 'Add landing',
                          icon: Icons.add,
                          variant: AppButtonVariant.soft,
                          isFullWidth: true,
                          onPressed: () {
                            setState(() {
                              _pigeons.add({
                                'name': 'Pigeon ${_pigeons.length + 1}',
                                'landing': '01:25 PM',
                                'avg': '13:25',
                                'isNew': true,
                              });
                            });
                          },
                        ),
                      ),
                    ],

                    // Total average card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.brandButton,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total average · 12 of 18 landed', style: AppTextStyles.caption.copyWith(color: AppColors.white90)),
                              const SizedBox(height: 2),
                              Text('13:02', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                            ],
                          ),
                          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                        ],
                      ),
                    ),

                    // Viewer stats engagement row
                    if (!widget.isOwner)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 18),
                                const SizedBox(width: 6),
                                Text('$_likeCount', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, color: AppColors.mut, size: 18),
                                const SizedBox(width: 6),
                                Text('870', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.emoji_events_outlined, color: AppColors.mut, size: 18),
                                const SizedBox(width: 6),
                                Text('18 flown', style: AppTextStyles.bodyBold.copyWith(color: AppColors.sub)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.isOwner)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: AppButton(
                  text: 'End live & save',
                  icon: Icons.stop_rounded,
                  variant: AppButtonVariant.dark,
                  isFullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
