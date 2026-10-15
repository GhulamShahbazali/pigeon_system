import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../network/socket_service.dart';
import '../local_storage/secure_storage_service.dart';
import '../../features/tournaments/data/tournaments_repository.dart';
import '../../features/posts/data/posts_repository.dart';
import '../../features/records/data/records_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/settings/data/user_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../localization/locale_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Storage
  final storageService = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(storageService);

  // 2. ApiClient (attaches the real session token once the user logs in)
  final apiClient = ApiClient(storage: storageService);
  sl.registerSingleton<ApiClient>(apiClient);

  // 3. Auth (real Google sign-in -> Firebase -> backend session)
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepository(sl<ApiClient>(), storageService));

  // 3b. Real-time socket (connect in background; reconnects on its own)
  final socket = SocketService(storageService);
  sl.registerSingleton<SocketService>(socket);
  // ignore: discarded_futures
  socket.connect();

  // 4. Feature Repositories
  sl.registerLazySingleton<TournamentsRepository>(() => TournamentsRepository(sl<ApiClient>()));
  sl.registerLazySingleton<PostsRepository>(() => PostsRepository(sl<ApiClient>()));
  sl.registerLazySingleton<RecordsRepository>(() => RecordsRepository(sl<ApiClient>()));
  sl.registerLazySingleton<UserRepository>(() => UserRepository(sl<ApiClient>()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepository(sl<ApiClient>()));

  // 5. Localization
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(storageService));
}
