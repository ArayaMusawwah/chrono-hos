import 'package:flutter/services.dart';

class DndService {
  static const MethodChannel _channel = MethodChannel('com.vicolo.chrono/bedtime');

  /// Whether the user has granted DND (notification policy) access.
  static Future<bool> isAllowed() async {
    final result = await _channel.invokeMethod<bool>('isDndAllowed');
    return result ?? false;
  }

  /// Opens Android's "Notification policy access" settings screen.
  static Future<void> requestAccess() =>
      _channel.invokeMethod('requestDndAccess');

  /// Enable or disable DND.
  /// No-op if DND access has not been granted.
  static Future<void> setDnd(bool enabled) =>
      _channel.invokeMethod('setDnd', {'enabled': enabled});

  /// Returns the current interruption filter value.
  /// [0] = ALL, [1] = PRIORITY, [2] = MESSAGES, [3] = NONE
  static Future<int> getCurrentMode() async {
    final value = await _channel.invokeMethod('getCurrentDndMode');
    return (value as int?) ?? 0;
  }
}
