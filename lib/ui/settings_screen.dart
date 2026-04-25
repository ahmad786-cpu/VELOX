// lib/ui/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('APPEARANCE'),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Use high-contrast dark theme',
                    trailing: Switch(
                      value: settings.isDarkMode,
                      onChanged: (val) => notifier.toggleDarkMode(val),
                      activeColor: AppConstants.accentCyan,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('DOWNLOAD PREFERENCES'),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.high_quality_outlined,
                    title: 'Default Quality',
                    subtitle: 'Resolution: ${settings.defaultQuality}',
                    onTap: () => _showQualityPicker(context, ref),
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.folder_open_outlined,
                    title: 'Download Path',
                    subtitle: settings.downloadPath,
                    onTap: () {}, // For now hardcoded but clickable
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('SYSTEM'),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: 'App Version',
                    subtitle: 'StreamVault v2.1.0-HF',
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.security_outlined,
                    title: 'Privacy Policy',
                  ),
                  
                  const SizedBox(height: 100), // Bottom nav space
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('SETTINGS',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
                color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (isDark ? Colors.black : Colors.white).withOpacity(0.5),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppConstants.accentCyan.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.accentIndigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppConstants.accentCyan, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12))
            : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qualities = ['2160p (4K)', '1440p (2K)', '1080p', '720p', '480p', '360p'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Default Quality',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...qualities.map((q) => ListTile(
                title: Text(q, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  ref.read(settingsProvider.notifier).setDefaultQuality(q);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
