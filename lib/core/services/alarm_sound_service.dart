import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmSoundSelection {
  const AlarmSoundSelection({
    required this.uri,
    required this.title,
  });

  final String uri;
  final String title;

  static AlarmSoundSelection? fromMap(Map<Object?, Object?>? map) {
    if (map == null) return null;

    final uri = map['uri']?.toString().trim() ?? '';
    final title = map['title']?.toString().trim() ?? '';

    if (uri.isEmpty) return null;

    return AlarmSoundSelection(
      uri: uri,
      title: title.isEmpty ? 'Selected alarm sound' : title,
    );
  }
}

class AlarmSoundService {
  static const MethodChannel _channel =
      MethodChannel('online_booking/alarm_sound');

  Future<AlarmSoundSelection?> pickAlarmSound({String? currentUri}) async {
    if (kIsWeb) return null;

    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'pickAlarmSound',
        <String, Object?>{
          'currentUri': currentUri,
        },
      );
      return AlarmSoundSelection.fromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<AlarmSoundSelection?> getDefaultAlarmSound() async {
    if (kIsWeb) return null;

    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getDefaultAlarmSound',
      );
      return AlarmSoundSelection.fromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
