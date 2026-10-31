import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  static final _fileDate = DateFormat('yyyy-MM-dd');

  Future<Directory> _folder(String userId) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/photo_of_the_day/$userId');
    await folder.create(recursive: true);
    return folder;
  }

  Future<File> _fileFor(String userId, DateTime day) async =>
      File('${(await _folder(userId)).path}/${_fileDate.format(day)}.jpg');

  Future<File?> photoFor(String userId, DateTime day) async {
    final file = await _fileFor(userId, day);
    return await file.exists() ? file : null;
  }

  Future<File> save(String userId, DateTime day, XFile photo) async {
    final file = await _fileFor(userId, day);
    await photo.saveTo(file.path);
    return file;
  }
}
