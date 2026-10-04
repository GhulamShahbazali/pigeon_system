import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PigeonFlyApp());
}

class PigeonFlyApp extends StatelessWidget {
  const PigeonFlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(AuthCheckRequestedEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'PigeonFly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
