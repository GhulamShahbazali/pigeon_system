import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';

import 'core/di/injection_container.dart';

import 'core/localization/locale_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android reads config from google-services.json via the Google Services plugin.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // ignore: avoid_print
    print('Firebase init skipped/failed: $e');
  }
  await initDependencies();
  runApp(const PigeonFlyApp());
}

class PigeonFlyApp extends StatelessWidget {
  const PigeonFlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(sl<AuthRepository>())..add(AuthCheckRequestedEvent()),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => sl<LocaleCubit>(),
        ),
      ],
      child: BlocBuilder<LocaleCubit, AppLanguage>(
        builder: (context, lang) {
          return MaterialApp.router(
            title: 'PigeonFly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: appRouter,
            locale: lang.locale,
            builder: (context, child) {
              return Directionality(
                textDirection: lang.direction,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
