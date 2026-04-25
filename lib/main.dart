// lib/main.dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/download_provider.dart';
import 'providers/navigation_provider.dart';
import 'services/download_service.dart';
import 'services/storage_service.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/settings_provider.dart';
import 'ui/downloads_screen.dart';
import 'ui/home_screen.dart';
import 'ui/library_screen.dart';
import 'ui/settings_screen.dart';

/// Top-level callback for FlutterDownloader (Android/iOS only).
@pragma('vm:entry-point')
void flutterDownloaderCallback(String id, int status, int progress) {
  final SendPort? port =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  port?.send([id, status, progress]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await StorageService.init();
  await DownloadService().init();

  runApp(const ProviderScope(child: StreamVaultApp()));
}

class StreamVaultApp extends ConsumerWidget {
  const StreamVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    LibraryScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
      floatingActionButton: currentIndex != 0
          ? _AddFab(
              onTap: () => ref.read(navigationProvider.notifier).setIndex(0))
          : null,
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final activeCount = tasks
        .where((t) =>
            t.status == AppDownloadStatus.running ||
            t.status == AppDownloadStatus.enqueued ||
            t.status == AppDownloadStatus.paused)
        .length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(navigationProvider.notifier).setIndex(i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.accentCyan,
        unselectedItemColor: isDark ? Colors.white24 : Colors.black26,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore,
                shadows: [Shadow(color: AppConstants.accentCyan, blurRadius: 10)]),
            label: 'BROWSE',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library,
                shadows: [Shadow(color: AppConstants.accentCyan, blurRadius: 10)]),
            label: 'LIBRARY',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount',
                  style: const TextStyle(fontSize: 9)),
              child: const Icon(Icons.download_for_offline_outlined),
            ),
            activeIcon: const Icon(Icons.download_for_offline,
                shadows: [Shadow(color: AppConstants.accentCyan, blurRadius: 10)]),
            label: 'DOWNLOADS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings,
                shadows: [Shadow(color: AppConstants.accentCyan, blurRadius: 10)]),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppConstants.liquidGradient,
          boxShadow: [
            BoxShadow(
                color: Color(0x66494BD6), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
