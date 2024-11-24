import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

int parseDuration(String duration) {
  final regex = RegExp(r'((\d*)h\s*)?(\d*)m*');
  final match = regex.firstMatch(duration);

  if (match == null) return 0;

  int hours = match.group(2)?.isEmpty ?? true ? 0 : int.parse(match.group(2)!);
  int minutes =
      match.group(3)?.isEmpty ?? true ? 0 : int.parse(match.group(3)!);

  return hours * 60 + minutes;
}

Future<void> configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<String> getDeviceIdentifier() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String identifier = '';

  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    identifier = iosInfo.identifierForVendor ?? ''; // unique ID on iOS
  } else if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    identifier = androidInfo.id; // unique ID on Android
  }

  return identifier;
}

int getEnhanced32BitFromFirestoreId(String id) {
  int hash = 0;

  for (final int unit in id.codeUnits) {
    hash = 31 * hash + unit;
    // Keep the number positive and within range after each iteration
    hash = hash % 0x7fffffff;
  }

  // Ensure we never return 0 by adding 1 if hash is 0
  return hash == 0 ? 1 : hash;
}
