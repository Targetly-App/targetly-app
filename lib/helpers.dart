import 'dart:ui';

import 'package:intl/intl.dart';

const dateFormat = 'yMMMMd';

String getFormattedDate(DateTime dateTime, {String format = dateFormat}) {
  var formatter = DateFormat(format);
  String formattedDate = formatter.format(dateTime);
  return formattedDate;
}

DateTime getDateTimeFromString(String date) {
  return DateFormat(dateFormat).parse(date);
}

/// This function generates a color from a text in pastel colors
Color generateColorFromText(String text) {
  final int hash = text.hashCode;
  final int r = (hash & 0xFF0000) >> 16;
  final int g = (hash & 0x00FF00) >> 8;
  final int b = (hash & 0x0000FF);
  return Color.fromARGB(255, r, g, b);
}
