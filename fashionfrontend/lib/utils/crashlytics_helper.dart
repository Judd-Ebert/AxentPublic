import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Helper class for Firebase Crashlytics integration
class CrashlyticsHelper {
  /// Log user actions and events
  static void logEvent(String message) {
    if (kDebugMode) {
      print('Crashlytics Log: $message');
    } else {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Set user identifier for crash reports
  static void setUserIdentifier(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Record non-fatal errors with context
  static void recordError(
    String error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, String>? context,
  }) {
    if (kDebugMode) {
      print('Crashlytics Error: $error');
      if (context != null) {
        print('Context: $context');
      }
    } else {
      final List<String> information = [];
      if (context != null) {
        context.forEach((key, value) => information.add('$key: $value'));
      }

      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: information.map((info) => 
          DiagnosticsProperty('info', info)
        ).toList(),
      );
    }
  }

  /// Record authentication events
  static void recordAuthEvent(String authMethod, {String? error}) {
    final message = error != null 
        ? '$authMethod failed: $error'
        : '$authMethod successful';
    logEvent(message);
  }

  /// Record user interactions
  static void recordUserInteraction(String interaction, {Map<String, String>? data}) {
    final contextString = data != null 
        ? ' - ${data.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
        : '';
    logEvent('User interaction: $interaction$contextString');
  }

  /// Record API errors
  static void recordApiError(
    String endpoint,
    String error, {
    int? statusCode,
    Map<String, String>? requestData,
  }) {
    final context = <String, String>{
      'endpoint': endpoint,
      'error': error,
      if (statusCode != null) 'status_code': statusCode.toString(),
      ...?requestData,
    };

    recordError(
      'API Error: $endpoint',
      StackTrace.current,
      fatal: false,
      context: context,
    );
  }
}