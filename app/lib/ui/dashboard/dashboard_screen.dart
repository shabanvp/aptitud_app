import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../home/app_home_screen.dart';
import '../home/home_screen.dart';
import '../gamification/store_screen.dart';
import '../tests/practice_screen.dart';
import '../multiplayer/multiplayer_screen.dart';
import '../home/company_events_screen.dart';
import '../home/company_home_screen.dart';
import './profile_screen.dart';
import './inbox_screen.dart';
import './leaderboard_screen.dart';
import '../home/event_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // ── CANDIDATE TABS ──────────────────────────────────────────────
  List<Widget> get _candidateScreens => [
    AppHomeScreen(
      onPractice: () => setState(() => _currentIndex = 1),
      onBattle: () => setState(() => _currentIndex = 2),
    ),
    const PracticeScreen(),
    const MultiplayerScreen(),
    const LeaderboardScreen(),
    const HomeScreen(),
  ];

  static const List<BottomNavigationBarItem> _candidateItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Practice'),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_esports_rounded),
      label: 'Battle',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.trending_up_rounded),
      label: 'Leaderboard',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  // ── COMPANY TABS ────────────────────────────────────────────────
  static const List<Widget> _companyScreens = [
    CompanyHomeScreen(),
    CompanyEventsScreen(),
    EventListScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _companyItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event_rounded),
      label: 'My Events',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.group_rounded),
      label: 'Candidates',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message_rounded),
      label: 'Messages',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isCompany = user?.isCompany ?? false;

    final screens = isCompany ? _companyScreens : _candidateScreens;
    final navItems = isCompany ? _companyItems : _candidateItems;

    // Guard index out of bounds
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Aptitude GO',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'store') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoreScreen()),
                );
              } else if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'store',
                child: Row(
                  children: [
                    Icon(Icons.store_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Store'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
          ),
        ],
      ),
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: navItems,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}
