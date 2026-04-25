// lib/services/web_download_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void triggerWebDownload(String url, String fileName) {
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..setAttribute('target', '_blank')
    ..click();
}
