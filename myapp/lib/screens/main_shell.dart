import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../services/location_service.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../state/chat_state.dart';
import '../state/notifications_state.dart';
import '../widgets/common/custom_bottom_nav.dart';
import '../widgets/common/loaders.dart';
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
  String? _lastUserId;
  double? _lastUserLat;
  double? _lastUserLon;

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
      context.read<ChatState>().reconnectActiveSubscriptions();
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

      final currentId = auth.currentUser?.id;
      _lastUserId = currentId;
      context.read<NotificationsState>().initUser(currentId);
      context.read<ActivitiesState>().fetchActivities();
      if (currentId != null) {
        context.read<ChatState>().fetchUserChats(currentId);
      }
    }
  }

  void _goToCreate() => setState(() => _currentIndex = 1);
  void _goToProfile() => setState(() => _currentIndex = 3);
  void _goToExplore() => setState(() => _currentIndex = 0);

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthState, bool>((a) => a.isLoading);
    final isAuthenticated = context.select<AuthState, bool>(
      (a) => a.isAuthenticated,
    );
    final needsProfile = context.select<AuthState, bool>((a) => a.needsProfile);
    final needsOnboarding = context.select<AuthState, bool>(
      (a) => a.needsOnboarding,
    );
    final currentUser = context.select<AuthState, dynamic>(
      (a) => a.currentUser,
    );

    if (isLoading) {
      return const Scaffold(
        body: Center(child: PageLoader(label: "Restoring session...")),
      );
    }

    if (isAuthenticated && needsProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushReplacementNamed('/complete-profile');
        }
      });
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const Center(child: PageLoader(label: "Setting up profile...")),
      );
    }

    if (isAuthenticated && needsOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      });
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const Center(child: PageLoader(label: "Loading interests...")),
      );
    }

    // Reactively ensure notifications, chat, and location state are kept in sync with auth updates
    final currentUserId = currentUser?.id as String?;
    final currentLat = currentUser?.latitude as double?;
    final currentLon = currentUser?.longitude as double?;

    final userChanged = _lastUserId != currentUserId;
    final coordsChanged = _lastUserLat != currentLat || _lastUserLon != currentLon;

    if (userChanged || coordsChanged) {
      final prevUserId = _lastUserId;
      _lastUserId = currentUserId;
      _lastUserLat = currentLat;
      _lastUserLon = currentLon;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (userChanged) {
          context.read<NotificationsState>().initUser(currentUserId);
          context.read<ChatState>().clear();
          if (currentUserId == null) {
            LocationService.clearCache();
            context.read<ActivitiesState>().clearLocation();
            context.read<ActivitiesState>().clearActivities();
          } else {
            if (prevUserId != null && prevUserId != currentUserId) {
              // Account switch: clear previous user's location state
              context.read<ActivitiesState>().clearLocation();
            }
            context.read<ActivitiesState>().fetchActivities();
            context.read<ChatState>().fetchUserChats(currentUserId);
          }
        }

        // Propagate resolved user GPS coordinates into ActivitiesState nearby discovery
        if (currentUserId != null && currentLat != null && currentLon != null) {
          final actState = context.read<ActivitiesState>();
          if (actState.place == null || userChanged) {
            final city = currentUser?.city as String?;
            final label = (city != null && city.trim().isNotEmpty)
                ? city.trim()
                : 'Current Location';
            actState.setPlace(
              SavedPlace(
                displayName: label,
                short: label,
                lat: currentLat,
                lon: currentLon,
                city: city ?? '',
              ),
            );
          }
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              ExploreScreen(
                onNavigateToCreate: _goToCreate,
                onNavigateToProfile: _goToProfile,
              ),
              CreatePlanScreen(onPlanCreated: _goToExplore),
              MessagesScreen(
                onNavigateToExplore: _goToExplore,
                onNavigateToCreate: _goToCreate,
              ),
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
            profile: currentUser,
            onComplete: () {
              setState(() => _showSplash = false);
            },
          ),
      ],
    );
  }
}
