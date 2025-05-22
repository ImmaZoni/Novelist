// lib/core/error_handler.dart
import 'package:flutter/foundation.dart'; // For kDebugMode

class ErrorHandler {
  static void recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) {
    if (kDebugMode) {
      print('-------------------------------- ERROR --------------------------------');
      if (reason != null) {
        print('Reason: $reason');
      }
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
      print('-----------------------------------------------------------------------');
    }

    // TODO: Integrate with a crash reporting service like Sentry or Firebase Crashlytics in production
    // if (!kDebugMode) {
    //   if (fatal) {
    //     FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason, fatal: true);
    //   } else {
    //     FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason);
    //   }
    // }
  }

  static void logInfo(String message, {String? scope}) {
    if (kDebugMode) {
      print('[INFO${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }

  static void logWarning(String message, {String? scope}) {
     if (kDebugMode) {
      print('[WARNING${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }
}

// Example usage:
// try {
//   // ... some operation
// } catch (e, s) {
//   ErrorHandler.recordError(e, s, reason: 'Failed to load books');
// }
//
// ErrorHandler.logInfo('User opened library screen.');