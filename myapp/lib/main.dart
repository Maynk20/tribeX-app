import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_and_policies_screen.dart';
import 'services/supabase_service.dart';
import 'state/activities_state.dart';
import 'state/auth_state.dart';
import 'state/chat_state.dart';
import 'state/notifications_state.dart';
import 'state/theme_state.dart';

import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Error Resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true; // handled
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Something went wrong while displaying this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await SupabaseService.initialize();

  runApp(const TribeXApp());
}

class TribeXApp extends StatelessWidget {
  const TribeXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ActivitiesState()),
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => NotificationsState()),
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, _) {
          return MaterialApp(
            title: 'tribeX - Find Local Fun',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            initialRoute: '/',
            routes: {
              '/': (_) => const MainShell(),
              '/auth': (_) => const AuthScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/onboarding': (_) => const OnboardingScreen(),
              '/complete-profile': (_) => const CompleteProfileScreen(),
              '/terms-and-policies': (_) => const TermsAndPoliciesScreen(),
            },
          );
        },
      ),
    );
  }
}