import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
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

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

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
