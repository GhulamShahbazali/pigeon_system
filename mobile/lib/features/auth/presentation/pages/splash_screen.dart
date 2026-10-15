import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const SplashScreen({super.key, this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    // Short brand flash only. Auth now resolves locally (no network round-trip on
    // launch), so the splash no longer waits on a slow/blocked server request.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _minTimeElapsed = true);
        _handleRouting(context.read<AuthBloc>().state);
      }
    });
  }

  void _handleRouting(AuthState state) {
    if (!_minTimeElapsed) return;
    // Don't navigate while auth status is still loading from storage or network
    if (state.status == AuthStatus.loading || state.status == AuthStatus.initial) return;

    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    if (state.status == AuthStatus.authenticated) {
      context.go('/home');
    } else if (state.status == AuthStatus.needsProfileSetup) {
      context.go('/auth/profile-setup');
    } else {
      context.go('/auth/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _handleRouting(state);
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.heroMeshSky,
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.white16,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.white30,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.flight_takeoff_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PigeonFly',
                    style: AppTextStyles.splashTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The home ground for pigeon-flying',
                    style: AppTextStyles.subtitleWhite,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
