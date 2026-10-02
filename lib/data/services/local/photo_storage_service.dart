import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// One photo per day, stored as `<documents>/photo_of_the_day/yyyy-MM-dd.jpg`.
class PhotoStorageService {
  static final _fileDate = DateFormat('yyyy-MM-dd');

  Future<Directory> _folder() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/photo_of_the_day');
    await folder.create(recursive: true);
    return folder;
  }

  Future<File> _fileFor(DateTime day) async =>
      File('${(await _folder()).path}/${_fileDate.format(day)}.jpg');

  Future<File?> photoFor(DateTime day) async {
    final file = await _fileFor(day);
    return await file.exists() ? file : null;
  }

  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) async {
    final result = <DateTime>{};
    for (final day in days) {
      if (await photoFor(day) != null) result.add(day);
    }
    return result;
  }

  Future<File> save(DateTime day, XFile photo) async {
    final file = await _fileFor(day);
    await photo.saveTo(file.path);
    return file;
  }
}
