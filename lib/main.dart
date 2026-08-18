import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/auth/auth_provider.dart';
import 'core/core_providers.dart';
import 'core/push/push_service.dart';
import 'core/routing/route_names.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorage.create();

  // Firebase is optional at this stage — no firebase_options.dart has been
  // generated yet (run `flutterfire configure` once google-services.json
  // is added). Guard so a missing/failed config never blocks app startup.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // no-op — app runs fine without push notifications
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const EazyPartnerApp(),
    ),
  );
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
          path: Routes.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: Routes.auth, builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: Routes.signup, builder: (context, state) => const SignupScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: Routes.home, builder: (context, state) => const MainShell()),
    ],
    // If a non-merchant account logs in, auth_provider immediately logs it
    // back out (status flips to loggedOut with an error) — this redirect
    // bounces the user off /home back to login the moment that happens,
    // instead of leaving them stranded on a dashboard with no session.
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onAuthRoute = state.matchedLocation == Routes.auth ||
          state.matchedLocation == Routes.signup ||
          state.matchedLocation == Routes.forgotPassword ||
          state.matchedLocation == Routes.splash;
      if (auth.status == SessionStatus.loggedOut &&
          !onAuthRoute &&
          state.matchedLocation == Routes.home) {
        return Routes.auth;
      }
      return null;
    },
    refreshListenable: _AuthRefreshListenable(ref),
  );
});

/// Bridges Riverpod's authProvider changes into a Listenable so GoRouter's
/// redirect re-evaluates whenever session status changes (e.g. the
/// merchant-role check in auth_provider logging a bad account back out).
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

class EazyPartnerApp extends ConsumerStatefulWidget {
  const EazyPartnerApp({super.key});

  @override
  ConsumerState<EazyPartnerApp> createState() => _EazyPartnerAppState();
}

class _EazyPartnerAppState extends ConsumerState<EazyPartnerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        pushService.onTokenRegister = (token) {
          ref.read(authProvider.notifier).registerPushToken(token);
        };
        await pushService.init();
      } catch (_) {
        // push notifications unavailable on this build/device — ignore
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final theme = ref.watch(effectiveThemeProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'EazyPartner',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
