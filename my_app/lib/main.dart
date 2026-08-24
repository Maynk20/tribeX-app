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
import 'state/activities_state.dart';
import 'state/auth_state.dart';
import 'state/chat_state.dart';
import 'state/notifications_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TribeXApp());
}

class TribeXApp extends StatelessWidget {
  const TribeXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ActivitiesState()),
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => NotificationsState()),
      ],
      child: MaterialApp(
        title: 'tribeX - Find Local Fun',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const MainShell(),
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/complete-profile': (_) => const CompleteProfileScreen(),
          '/terms-and-policies': (_) => const TermsAndPoliciesScreen(),
        },
      ),
    );
  }
}
