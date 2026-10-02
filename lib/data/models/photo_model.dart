import 'dart:io';

/// The photo saved for one day ("photo of the day").
class DailyPhoto {
  const DailyPhoto({required this.day, required this.file});

  /// Day the photo belongs to, without time.
  final DateTime day;

  /// Where the image is stored on the device.
  final File file;
}
