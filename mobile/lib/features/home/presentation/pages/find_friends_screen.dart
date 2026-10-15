import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../settings/data/user_repository.dart';
import '../../data/discovery_repository.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final DiscoveryRepository _discovery = sl<DiscoveryRepository>();
  final UserRepository _userRepo = sl<UserRepository>();
  final _searchController = TextEditingController();

  List<UserCardModel> _suggestions = [];
  List<UserCardModel> _results = [];
  bool _loading = true;
  bool _searchLoading = false;
  String _query = '';
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final res = await _discovery.suggestions();
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _suggestions = (res as dynamic).data as List<UserCardModel>;
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searchLoading = false;
      });
      return;
    }
    // Debounce: only the latest keystroke's request is applied.
    final token = ++_searchToken;
    setState(() => _searchLoading = true);
    Future.delayed(const Duration(milliseconds: 350), () async {
      if (token != _searchToken || !mounted) return;
      final res = await _discovery.searchUsers(q);
      if (token != _searchToken || !mounted) return;
      setState(() {
        if (res.isSuccess) _results = (res as dynamic).data as List<UserCardModel>;
        _searchLoading = false;
      });
    });
  }

  Future<void> _toggleFollow(UserCardModel user) async {
    final wasFollowing = user.isFollowing;
    setState(() => user.isFollowing = !wasFollowing);
    final res = wasFollowing
        ? await _userRepo.unfollow(user.id)
        : await _userRepo.follow(user.id);
    if (!mounted) return;
    if (res.isFailure) {
      setState(() => user.isFollowing = wasFollowing); // revert on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;
    final list = isSearching ? _results : _suggestions;

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
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
                        onChanged: _onSearchChanged,
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
                          _onSearchChanged('');
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: AppColors.mut, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(child: _buildList(isSearching, list)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isSearching, List<UserCardModel> list) {
    if ((isSearching && _searchLoading) || (!isSearching && _loading)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(32)),
              child: const Icon(Icons.people_outline_rounded, size: 32, color: AppColors.mut),
            ),
            const SizedBox(height: 14),
            Text(isSearching ? 'No people found' : 'No suggestions yet', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              isSearching ? 'Try another name or @username' : 'Check back as more flyers join',
              style: AppTextStyles.body.copyWith(color: AppColors.mut),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            isSearching
                ? 'People · ${list.length} ${list.length == 1 ? 'result' : 'results'}'
                : 'Suggested for you',
            style: AppTextStyles.labelUppercase,
          ),
        ),
        ...list.map(_userRow),
      ],
    );
  }

  Widget _userRow(UserCardModel user) {
    void openProfile() => context.push('/user/${user.id}');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: openProfile,
            child: AppAvatar(
              name: user.displayName,
              imageUrl: user.photoUrl,
              size: 46,
              gradient: AppColors.avatarBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: openProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    '${user.handle} · ${user.followersLabel}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mut),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _toggleFollow(user),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: user.isFollowing ? AppColors.soft : AppColors.brand,
                borderRadius: BorderRadius.circular(10),
                border: user.isFollowing ? Border.all(color: AppColors.line) : null,
              ),
              child: Text(
                user.isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: user.isFollowing ? AppColors.ink2 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
