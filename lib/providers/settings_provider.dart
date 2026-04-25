// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class SettingsState {
  final bool isDarkMode;
  final String defaultQuality;
  final String downloadPath;

  const SettingsState({
    this.isDarkMode = true,
    this.defaultQuality = '1080p',
    this.downloadPath = r'D:\StreamVault',
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? defaultQuality,
    String? downloadPath,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      downloadPath: downloadPath ?? this.downloadPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'defaultQuality': defaultQuality,
    'downloadPath': downloadPath,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      isDarkMode: json['isDarkMode'] ?? true,
      defaultQuality: json['defaultQuality'] ?? '1080p',
      downloadPath: json['downloadPath'] ?? r'D:\StreamVault',
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final saved = StorageService.getSettings();
    if (saved != null) {
      return SettingsState.fromJson(Map<String, dynamic>.from(saved));
    }
    return const SettingsState();
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
    _persist();
  }

  void setDefaultQuality(String quality) {
    state = state.copyWith(defaultQuality: quality);
    _persist();
  }

  void setDownloadPath(String path) {
    state = state.copyWith(downloadPath: path);
    _persist();
  }

  void _persist() {
    StorageService.saveSettings(state.toJson());
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});
