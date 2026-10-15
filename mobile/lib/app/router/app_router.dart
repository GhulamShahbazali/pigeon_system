import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/google_chooser_screen.dart';
import '../../features/auth/presentation/pages/profile_setup_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import '../pages/main_shell_page.dart';
import '../../features/tournaments/presentation/pages/create_tournament_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_participants_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_detail_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_winner_screen.dart';
import '../../features/tournaments/presentation/pages/record_day_result_screen.dart';
import '../../features/posts/data/posts_repository.dart';
import '../../features/posts/presentation/pages/create_post_screen.dart';
import '../../features/posts/presentation/pages/post_detail_screen.dart';
import '../../features/records/presentation/pages/add_record_screen.dart';
import '../../features/records/presentation/pages/live_record_screen.dart';
import '../../features/records/presentation/pages/private_record_detail_screen.dart';
import '../../features/records/presentation/pages/auto_ended_record_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/edit_profile_screen.dart';
import '../../features/settings/presentation/pages/language_settings_screen.dart';
import '../../features/settings/presentation/pages/notification_privacy_settings_screen.dart';
import '../../features/settings/presentation/pages/other_user_profile_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/chat/presentation/pages/inbox_screen.dart';
import '../../features/chat/presentation/pages/message_requests_screen.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_search_screen.dart';
import '../../features/tournaments/presentation/pages/user_tournaments_screen.dart';
import '../../features/records/presentation/pages/records_search_screen.dart';
import '../../features/chat/presentation/pages/chat_search_screen.dart';
import '../../features/home/presentation/pages/find_friends_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth/sign-in',
      builder: (context, state) => BlocListener<AuthBloc, AuthState>(
        listener: (context, s) {
          if (s.status == AuthStatus.authenticated) {
            context.go('/home');
          } else if (s.status == AuthStatus.needsProfileSetup) {
            context.go('/auth/profile-setup');
          } else if (s.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.errorMessage ?? 'Sign-in failed')),
            );
          }
        },
        child: SignInScreen(
          // Trigger the REAL Google sign-in (native picker -> Firebase -> backend).
          onGoogleSignIn: () => context.read<AuthBloc>().add(AuthGoogleSignInRequestedEvent()),
          onAppleSignIn: () => context.read<AuthBloc>().add(AuthAppleSignInRequestedEvent()),
        ),
      ),
    ),
    GoRoute(
      path: '/auth/chooser',
      builder: (context, state) => GoogleChooserScreen(
        onAccountSelected: (email) => context.push('/auth/profile-setup'),
        onAddAccount: () => context.push('/auth/profile-setup'),
      ),
    ),
    GoRoute(
      path: '/auth/profile-setup',
      // The screen dispatches AuthProfileSubmittedEvent itself and calls onContinue
      // once the backend completes signup (status = authenticated).
      builder: (context, state) => ProfileSetupScreen(
        onContinue: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/auth/welcome',
      builder: (context, state) => WelcomeScreen(
        onGoToTournaments: () => context.go('/home'),
        onCreateTournament: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShellPage(),
    ),
    // Tournaments routes
    GoRoute(
      path: '/tournaments/create',
      builder: (context, state) => const CreateTournamentScreen(),
    ),
    GoRoute(
      path: '/tournaments/participants',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return TournamentParticipantsScreen(
          tournamentId: state.uri.queryParameters['tournamentId'],
          tournamentData: data,
        );
      },
    ),
    GoRoute(
      path: '/tournaments/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'city-loft';
        final isOwner = state.uri.queryParameters['isOwner'] == 'true';
        return TournamentDetailScreen(
          tournamentId: id,
          isOwner: isOwner,
        );
      },
    ),
    GoRoute(
      path: '/tournaments/record-day',
      builder: (context, state) => const RecordDayResultScreen(),
    ),
    GoRoute(
      path: '/tournaments/winner/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final title = state.uri.queryParameters['title'];
        return TournamentWinnerScreen(
          tournamentId: id,
          tournamentTitle: title,
        );
      },
    ),
    GoRoute(
      path: '/profile/tournaments',
      builder: (context, state) {
        final initialTab = state.uri.queryParameters['tab'];
        return UserTournamentsScreen(initialTab: initialTab);
      },
    ),
    // Posts routes
    GoRoute(
      path: '/posts/create',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/posts/detail',
      builder: (context, state) {
        final post = state.extra;
        if (post is PostModel) {
          return PostDetailScreen(
            postId: post.id,
            authorName: post.author.displayName,
            authorHandle: '@${post.author.username}',
            authorPhotoUrl: post.author.photoUrl,
            authorId: post.author.id,
            timeAgo: 'Recently',
            content: post.content,
            imageUrl: post.imageUrl,
            likes: post.likeCount,
            shares: post.shareCount,
            views: post.viewCount.toString(),
            isLiked: post.isLiked,
          );
        }
        return const PostDetailScreen();
      },
    ),
    // Records routes
    GoRoute(
      path: '/records/create',
      builder: (context, state) => const AddRecordScreen(),
    ),
    GoRoute(
      path: '/records/live',
      builder: (context, state) => const LiveRecordScreen(),
    ),
    GoRoute(
      path: '/records/live/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final isOwner = state.uri.queryParameters['isOwner'] == 'true';
        final loftName = state.uri.queryParameters['loftName'];
        return LiveRecordScreen(
          recordId: id,
          isOwner: isOwner,
          loftName: loftName,
        );
      },
    ),
    GoRoute(
      path: '/records/private',
      builder: (context, state) => const PrivateRecordDetailScreen(),
    ),
    GoRoute(
      path: '/records/auto-ended',
      builder: (context, state) => const AutoEndedRecordScreen(),
    ),
    // Settings routes
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationPrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/user/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        // extra may be a PostAuthorModel (from a post's author tap) for an instant
        // name/photo before the full profile loads; else fall back to a query param.
        String? initialName = state.uri.queryParameters['name'];
        String? initialPhoto;
        try {
          initialName ??= (extra as dynamic)?.displayName as String?;
          initialPhoto = (extra as dynamic)?.photoUrl as String?;
        } catch (_) {}
        return OtherUserProfileScreen(
          userId: id,
          initialName: initialName,
          initialPhotoUrl: initialPhoto,
        );
      },
    ),
    // Notifications & Chat routes
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const InboxScreen(),
    ),
    GoRoute(
      path: '/messages/requests',
      builder: (context, state) => const MessageRequestsScreen(),
    ),
    GoRoute(
      path: '/messages/chat/:name',
      builder: (context, state) => ChatScreen(
        contactName: state.pathParameters['name'] ?? 'Ahmed Loft',
      ),
    ),
    GoRoute(
      path: '/tournaments/search',
      builder: (context, state) => const TournamentSearchScreen(),
    ),
    GoRoute(
      path: '/records/search',
      builder: (context, state) => const RecordsSearchScreen(),
    ),
    GoRoute(
      path: '/messages/search',
      builder: (context, state) => const ChatSearchScreen(),
    ),
    GoRoute(
      path: '/discovery/find-friends',
      builder: (context, state) => const FindFriendsScreen(),
    ),
  ],
);
