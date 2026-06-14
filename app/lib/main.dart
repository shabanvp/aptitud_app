import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/game_state_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/event_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/landing/landing_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameStateProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: const AptitudeGoApp(),
    ),
  );
}

class AptitudeGoApp extends StatelessWidget {
  const AptitudeGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aptitude GO',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final viewInsets = mediaQuery.viewInsets;
        final safeInsets = viewInsets.copyWith(
          left: viewInsets.left < 0 ? 0 : viewInsets.left,
          top: viewInsets.top < 0 ? 0 : viewInsets.top,
          right: viewInsets.right < 0 ? 0 : viewInsets.right,
          bottom: viewInsets.bottom < 0 ? 0 : viewInsets.bottom,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(viewInsets: safeInsets),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Sync real user data into GameStateProvider whenever auth state changes
          if (auth.isAuthenticated && auth.currentUser != null) {
            final user = auth.currentUser!;
            // Use addPostFrameCallback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<GameStateProvider>(
                context,
                listen: false,
              ).syncFromUser(
                coins: user.coins,
                lives: user.lives,
                level: user.level,
                exp: user.exp,
              );
            });
            return const DashboardScreen();
          }
          // Show loading spinner while session is being restored
          if (auth.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 64,
                      color: Color(0xFF8B5CF6),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            );
          }
          return const LandingScreen();
        },
      ),
    );
  }
}
