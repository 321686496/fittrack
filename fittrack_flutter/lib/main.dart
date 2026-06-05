import 'package:flutter/material.dart';
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'pages/home_page.dart';
import 'pages/plan_page.dart';
import 'pages/training_page.dart';
import 'pages/stats_page.dart';
import 'pages/exercise_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/records_page.dart';
import 'widgets/bottom_nav.dart';

void main() {
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  String _themeId = 'iron-forge';

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    _themeId = settings['theme'] ?? 'iron-forge';
    if (!Storage.hasData()) {
      Storage.initDemoData();
    }
  }

  void _switchTheme(String id) {
    setState(() {
      _themeId = id;
      final settings = Storage.getSettings();
      Storage.saveSettings({...settings, 'theme': id});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_themeId),
      home: AppShell(onThemeChanged: _switchTheme),
    );
  }
}

class AppShell extends StatefulWidget {
  final void Function(String themeId) onThemeChanged;

  const AppShell({super.key, required this.onThemeChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _currentPage = 'home';
  Map<String, dynamic>? _trainingParams;

  static const _navPages = ['home', 'plan', 'records', 'stats', 'profile'];

  void _navigate(String page, {Map<String, dynamic>? params}) {
    if (page == 'training' && params != null) {
      _trainingParams = params;
    }
    setState(() {
      _currentPage = page;
    });
  }

  int get _navIndex {
    switch (_currentPage) {
      case 'home':
        return 0;
      case 'plan':
        return 1;
      case 'records':
        return 2;
      case 'stats':
        return 3;
      case 'profile':
        return 4;
      default:
        return 0;
    }
  }

  bool get _showNav => !_noNavPages.contains(_currentPage);

  static const _noNavPages = ['training', 'settings'];

  Widget _buildPage() {
    switch (_currentPage) {
      case 'home':
        return HomePage(onNavigate: _navigate);
      case 'plan':
        return PlanPage(onNavigate: _navigate);
      case 'training':
        return TrainingPage(
          params: _trainingParams ?? {},
          onNavigate: _navigate,
        );
      case 'stats':
        return StatsPage(onNavigate: _navigate);
      case 'exercise':
        return ExercisePage(onNavigate: _navigate);
      case 'profile':
        return ProfilePage(onNavigate: _navigate);
      case 'settings':
        return SettingsPage(
          onNavigate: _navigate,
          onThemeChanged: widget.onThemeChanged,
        );
      case 'records':
        return RecordsPage(onNavigate: _navigate);
      default:
        return HomePage(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildPage(),
                ),
              ),
            ),
            if (_showNav)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: BottomNav(
                    currentIndex: _navIndex,
                    onTap: (index) {
                      _navigate(_navPages[index]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
