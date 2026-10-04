import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_event.dart';
import '../bloc/navigation_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/tournaments/presentation/pages/tournaments_list_screen.dart';
import '../../features/records/presentation/pages/records_list_screen.dart';
import '../../features/settings/presentation/pages/profile_screen.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(),
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          final pages = [
            const HomeScreen(),
            const TournamentsListScreen(),
            const RecordsListScreen(),
            const ProfileScreen(),
          ];

          return Scaffold(
            body: IndexedStack(
              index: state.selectedIndex,
              children: pages,
            ),
            bottomNavigationBar: AppBottomNav(
              selectedIndex: state.selectedIndex,
              onTabSelected: (index) {
                context.read<NavigationBloc>().add(NavigationTabChangedEvent(index));
              },
              onCreatePressed: () {
                _showCreateModal(context);
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create New',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 14),
                _buildCreateOption(
                  icon: Icons.emoji_events_outlined,
                  title: 'New Tournament',
                  subtitle: 'Single or multi-day competition',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/tournaments/create');
                  },
                ),
                const Divider(color: AppColors.hair, height: 1),
                _buildCreateOption(
                  icon: Icons.flight_takeoff_outlined,
                  title: 'Daily Flight Record',
                  subtitle: 'Track your loft routine live or private',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/records/create');
                  },
                ),
                const Divider(color: AppColors.hair, height: 1),
                _buildCreateOption(
                  icon: Icons.edit_note_outlined,
                  title: 'New Post',
                  subtitle: 'Share flight photos and updates',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/posts/create');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brand, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mut, size: 20),
          ],
        ),
      ),
    );
  }
}
