import 'package:flutter/foundation.dart';

/// Safe runtime logs that can be collected from Flutter's Android log output.
/// Never pass credentials, request bodies, emails, or user supplied text here.
abstract final class AppLogger {
  static void info(String event, {String? detail}) =>
      _write('INFO', event, detail: detail);

  static void warning(String event, {String? detail}) =>
      _write('WARN', event, detail: detail);

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    String? detail,
  }) {
    final safeDetail = [
      if (detail != null && detail.isNotEmpty) detail,
      if (error != null) 'errorType=${error.runtimeType}',
    ].join(' ');
    _write('ERROR', event, detail: safeDetail.isEmpty ? null : safeDetail);

    // Stack traces can contain local paths and are useful during development.
    if (kDebugMode && stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, label: '[YOMU][DEBUG] $event');
    }
  }

  static void _write(String level, String event, {String? detail}) {
    final suffix = detail == null || detail.isEmpty ? '' : ' | $detail';
    debugPrint('[YOMU][$level] $event$suffix');
  }
}
