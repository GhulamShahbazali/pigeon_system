import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final _searchController = TextEditingController();

  final List<String> _recentSearches = ['ahmed loft', '@bilal_racing', 'rashid'];

  final List<Map<String, dynamic>> _allPeople = [
    {
      'id': 'ahmed',
      'name': 'Ahmed Loft',
      'handle': '@ahmedloft',
      'followers': '4.2k followers',
      'isVerified': true,
      'isFollowing': false,
      'initial': 'A',
      'gradient': AppColors.avatarBlue,
      'location': 'Lahore, PK',
    },
    {
      'id': 'rashid',
      'name': 'Rashid Lofts',
      'handle': '@rashid_pk',
      'followers': '1.1k followers',
      'isVerified': false,
      'isFollowing': false,
      'initial': 'R',
      'gradient': AppColors.avatarPurple,
      'location': 'Gujranwala, PK',
    },
    {
      'id': 'sohail',
      'name': 'Sohail Khan',
      'handle': '@sohail.k',
      'followers': '860 followers',
      'isVerified': false,
      'isFollowing': false,
      'initial': 'S',
      'gradient': AppColors.avatarGold,
      'location': 'Rawalpindi, PK',
    },
    {
      'id': 'bilal',
      'name': 'Bilal Racing',
      'handle': '@bilal_racing',
      'followers': '2.7k followers',
      'isVerified': false,
      'isFollowing': false,
      'initial': 'B',
      'gradient': AppColors.avatarBlue,
      'location': 'Sialkot, PK',
    },
    {
      'id': 'kashif',
      'name': 'Kashif Ali',
      'handle': '@kashif.loft',
      'followers': '540 followers',
      'isVerified': false,
      'isFollowing': false,
      'initial': 'K',
      'gradient': AppColors.avatarGreen,
      'location': 'Faisalabad, PK',
    },
    {
      'id': 'usman',
      'name': 'Usman Tariq',
      'handle': '@usman.t',
      'followers': '430 followers',
      'isVerified': false,
      'isFollowing': false,
      'initial': 'U',
      'gradient': AppColors.avatarPurple,
      'location': 'Lahore, PK',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    final searchResults = _allPeople.where((user) {
      return (user['name'] as String).toLowerCase().contains(query) ||
          (user['handle'] as String).toLowerCase().contains(query);
    }).toList();

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
        title: Text(isSearching ? 'Search people' : 'Find friends', style: AppTextStyles.h2),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded, size: 22, color: AppColors.ink),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Search Input matching wireframe 1, 2, 3
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSearching ? AppColors.brand : AppColors.line,
                  width: isSearching ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyBold,
                      decoration: InputDecoration(
                        hintText: 'Search name or @username…',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mut),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (isSearching)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.mut,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // If query is empty but user focused or recent available -> Show Recent Searches (wireframe screen 3)
            if (!isSearching && _recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent', style: AppTextStyles.labelUppercase),
                  GestureDetector(
                    onTap: () => setState(() => _recentSearches.clear()),
                    child: Text(
                      'Clear',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.brand),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((term) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = term;
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 15, color: AppColors.mut),
                          const SizedBox(width: 6),
                          Text(term, style: AppTextStyles.captionBold),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _recentSearches.remove(term);
                              });
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.mut),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSearching
                      ? 'People · ${searchResults.length} ${searchResults.length == 1 ? 'result' : 'results'}'
                      : 'Suggested for you',
                  style: AppTextStyles.labelUppercase,
                ),
                if (!isSearching)
                  Text(
                    'See all',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.brand),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // User Rows (.urow matching wireframe 1 & 2)
            if (isSearching && searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 32, color: AppColors.mut),
                      ),
                      const SizedBox(height: 14),
                      Text('No people found', style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching for another name or @username',
                        style: AppTextStyles.body.copyWith(color: AppColors.mut),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(isSearching ? searchResults : _allPeople).map((user) {
                final isFollowing = user['isFollowing'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                      boxShadow: AppShadows.xs,
                    ),
                    child: Row(
                      children: [
                        // Avatar tap -> open profile
                        InkWell(
                          onTap: () {
                            context.push(
                              '/user/${user['id']}?name=${Uri.encodeComponent(user['name'])}&handle=${Uri.encodeComponent(user['handle'])}&location=${Uri.encodeComponent(user['location'])}',
                            );
                          },
                          child: AppAvatar(
                            text: user['initial'] as String,
                            size: 46,
                            gradient: user['gradient'] as LinearGradient,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & meta
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '/user/${user['id']}?name=${Uri.encodeComponent(user['name'])}&handle=${Uri.encodeComponent(user['handle'])}&location=${Uri.encodeComponent(user['location'])}',
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(user['name'] as String, style: AppTextStyles.bodyBold),
                                    if (user['isVerified'] == true) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.brand),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${user['handle']} · ${user['followers']}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Actions: Message + Follow (matching .ract in wireframe)
                        Row(
                          children: [
                            // 💬 Message button
                            InkWell(
                              onTap: () {
                                context.push('/messages/chat/${Uri.encodeComponent(user['name'])}');
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.soft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 17,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Follow / Following button
                            InkWell(
                              onTap: () {
                                setState(() {
                                  user['isFollowing'] = !isFollowing;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isFollowing ? AppColors.soft : AppColors.brand,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isFollowing ? Border.all(color: AppColors.line) : null,
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isFollowing ? AppColors.ink2 : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
