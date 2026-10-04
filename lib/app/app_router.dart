import 'package:go_router/go_router.dart';

import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/unlock_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/unlock', builder: (context, state) => const UnlockScreen()),
    GoRoute(
      path: '/ganti-password',
      builder: (context, state) => const ChangePasswordScreen(force: true),
    ),
    GoRoute(path: '/dashboard', builder: (context, state) => const AppShell()),
  ],
);
