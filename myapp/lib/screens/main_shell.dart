import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../state/notifications_state.dart';
import '../widgets/common/custom_bottom_nav.dart';
import '../widgets/common/welcome_splash.dart';
import 'create_plan_screen.dart';
import 'explore_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ActivitiesState>().reconnectRealtime();
    }
  }

  void _checkGates() {
    final auth = context.read<AuthState>();
    if (auth.isLoading) return;

    if (auth.isAuthenticated) {
      if (auth.needsProfile) {
        Navigator.of(context).pushReplacementNamed('/complete-profile');
        return;
      }

      if (auth.needsOnboarding) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      }

      final notifs = context.read<NotificationsState>();
      notifs.initUser(auth.currentUser?.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isAuthenticated && auth.needsProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/complete-profile');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (auth.isAuthenticated && auth.needsOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              ExploreScreen(
                onNavigateToCreate: () => setState(() => _currentIndex = 1),
                onNavigateToProfile: () => setState(() => _currentIndex = 3),
              ),
              CreatePlanScreen(
                onPlanCreated: () => setState(() => _currentIndex = 0),
              ),
              const MessagesScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
          ),
        ),

        // Initial animated welcome splash
        if (_showSplash)
          WelcomeSplash(
            profile: auth.currentUser,
            onComplete: () {
              setState(() => _showSplash = false);
            },
          ),
      ],
    );
  }
}
