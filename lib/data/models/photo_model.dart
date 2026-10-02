import 'dart:io';

class DailyPhoto {
  const DailyPhoto({required this.day, required this.file});

  final DateTime day;
  final File file;
}
