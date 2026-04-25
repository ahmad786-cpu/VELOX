// lib/services/storage_service.dart
//
// Pure storage — no Riverpod, no circular dependency.
// DownloadProvider calls this; StorageService never calls DownloadProvider.

import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../providers/download_provider.dart' show DownloadTaskInfo;

class StorageService {
  static const String _boxName = 'downloads_box_v2';
  static const String _settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await Hive.box(_settingsBoxName).put('app_settings', settings);
  }

  static Map? getSettings() {
    final box = Hive.box(_settingsBoxName);
    return box.get('app_settings');
  }

  static Future<void> saveTask(DownloadTaskInfo task) async {
    final box = Hive.box(_boxName);
    await box.put(task.taskId, {
      'taskId':         task.taskId,
      'title':          task.title,
      'thumbnailUrl':   task.thumbnailUrl,
      'progress':       task.progress,
      'status':         task.status.index,
      'localPath':      task.localPath,
      'downloadedSize': task.downloadedSize,
      'totalSize':      task.totalSize,
      'url':            task.url,
      'audioUrl':       task.audioUrl,
    });
  }

  static List<DownloadTaskInfo> getAllTasks() {
    final box = Hive.box(_boxName);
    return box.values.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final statusIdx = (m['status'] as int?) ?? 0;
      final status = statusIdx < AppDownloadStatus.values.length
          ? AppDownloadStatus.values[statusIdx]
          : AppDownloadStatus.undefined;
      return DownloadTaskInfo(
        taskId:         m['taskId'] as String? ?? '',
        title:          m['title'] as String? ?? '',
        thumbnailUrl:   m['thumbnailUrl'] as String? ?? '',
        progress:       (m['progress'] as int?) ?? 0,
        status:         status,
        localPath:      m['localPath'] as String?,
        downloadedSize: (m['downloadedSize'] as int?) ?? 0,
        totalSize:      (m['totalSize'] as int?) ?? 0,
        url:            m['url'] as String?,
        audioUrl:       m['audioUrl'] as String?,
      );
    }).toList();
  }

  static Future<void> deleteTask(String taskId) async {
    await Hive.box(_boxName).delete(taskId);
  }

  static Future<void> clearAll() async {
    await Hive.box(_boxName).clear();
  }
}
