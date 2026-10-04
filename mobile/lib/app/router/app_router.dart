import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/google_chooser_screen.dart';
import '../../features/auth/presentation/pages/profile_setup_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import '../pages/main_shell_page.dart';
import '../../features/tournaments/presentation/pages/create_tournament_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_participants_screen.dart';
import '../../features/tournaments/presentation/pages/tournament_detail_screen.dart';
import '../../features/tournaments/presentation/pages/record_day_result_screen.dart';
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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(
        onFinish: () => context.go('/auth/sign-in'),
      ),
    ),
    GoRoute(
      path: '/auth/sign-in',
      builder: (context, state) => SignInScreen(
        onGoogleSignIn: () => context.push('/auth/chooser'),
        onAppleSignIn: () => context.push('/auth/profile-setup'),
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
      builder: (context, state) => ProfileSetupScreen(
        onContinue: () => context.go('/auth/welcome'),
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
      builder: (context, state) => const TournamentParticipantsScreen(),
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
    // Posts routes
    GoRoute(
      path: '/posts/create',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/posts/detail',
      builder: (context, state) => const PostDetailScreen(),
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
        final id = state.pathParameters['id'] ?? 'user';
        final name = state.uri.queryParameters['name'] ?? (id == 'rashid' ? 'Rashid Lofts' : id == 'naveed' ? 'Naveed Pigeons' : id == 'ahmed' ? 'Ahmed Loft' : id == 'kashif' ? 'Kashif Pigeons' : 'Kashif Ali');
        final handle = state.uri.queryParameters['handle'] ?? '@$id';
        final location = state.uri.queryParameters['location'] ?? 'Lahore, PK';
        return OtherUserProfileScreen(
          name: name,
          handle: handle,
          location: location,
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
  ],
);
