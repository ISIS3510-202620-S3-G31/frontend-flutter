import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<File> save(DateTime day, XFile photo) async {
    final file = await _fileFor(day);
    await photo.saveTo(file.path);
    return file;
  }
}
