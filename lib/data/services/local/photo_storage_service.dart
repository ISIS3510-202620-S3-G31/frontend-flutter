import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps one photo per day on the device, as `<documents>/photo_of_the_day/yyyy-MM-dd.jpg`.
class PhotoStore {
  static final _fileDate = DateFormat('yyyy-MM-dd');

  Future<Directory> _folder() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/photo_of_the_day');
    await folder.create(recursive: true);
    return folder;
  }

  Future<File> _fileFor(DateTime day) async =>
      File('${(await _folder()).path}/${_fileDate.format(day)}.jpg');

  /// The photo saved for [day], or null if there is none.
  Future<File?> photoFor(DateTime day) async {
    final file = await _fileFor(day);
    return await file.exists() ? file : null;
  }

  /// Which of [days] already have a photo.
  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) async {
    final result = <DateTime>{};
    for (final day in days) {
      if (await photoFor(day) != null) result.add(day);
    }
    return result;
  }

  /// Copies [photo] (from the camera or the gallery) as the photo of [day].
  Future<File> save(DateTime day, XFile photo) async {
    final file = await _fileFor(day);
    await photo.saveTo(file.path);
    return file;
  }
}
