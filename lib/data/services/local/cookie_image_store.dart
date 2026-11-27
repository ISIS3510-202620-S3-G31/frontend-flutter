// here the photos are saved as private files of the app.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';


class CookieImageStore {
  CookieImageStore({Directory? folder}) : _customFolder = folder;

  final Directory? _customFolder;

  Future<Directory> _root() async {
    final folder =
        _customFolder ??
        Directory('${(await getApplicationDocumentsDirectory()).path}/cookies');
    await folder.create(recursive: true);
    return folder;
  }

  /// Where a cookie's photo goes, relative to the store.
  static String relativePathFor(String userId, String cookieId) =>
      '$userId/$cookieId.jpg';

  Future<File> fileFor(String relativePath) async =>
      File('${(await _root()).path}/$relativePath');

  /// Writes the photo and returns its relative path.

  Future<String> save(String userId, String cookieId, Uint8List jpeg) async {
    final relative = relativePathFor(userId, cookieId);
    final file = await fileFor(relative);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsBytes(jpeg, flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    return relative;
  }

  /// The photo's bytes, or null when the file is not on this phone.
  Future<Uint8List?> read(String relativePath) async {
    final file = await fileFor(relativePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Size of the photo in bytes, 0 when it is not on this phone.
  Future<int> sizeOf(String relativePath) async {
    final file = await fileFor(relativePath);
    return await file.exists() ? file.length() : 0;
  }

  /// Deleting a file that is not there is not an error.
  Future<void> delete(String relativePath) async {
    final file = await fileFor(relativePath);
    if (await file.exists()) await file.delete();
  }
}
