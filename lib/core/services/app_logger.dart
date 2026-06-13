import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppLogger {
  const AppLogger._();

  static Logger get(String name) => Logger(name);
}

void setupAppLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((record) {
    final message = [
      record.time.toIso8601String(),
      record.level.name,
      record.loggerName,
      record.message,
      if (record.error != null) 'error=${record.error}',
      if (record.stackTrace != null) 'stack=${record.stackTrace}',
    ].join(' | ');

    debugPrint(message);
  });
}
