import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Where a shared card goes: the app's private copy, the phone's gallery and
/// the share sheet.
class FortuneShareService {
  const FortuneShareService();

  /// The app's own copy, in its private documents folder, one folder per
  /// account. It is what the Shared list shows and what is shared, so it does
  /// not depend on the user keeping the gallery copy.
  Future<File> keepCopy(String userId, int cookieId, Uint8List png) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/fortune_cards/$userId');
    await folder.create(recursive: true);
    final file = File('${folder.path}/card_$cookieId.png');
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  /// Public storage on purpose: the user asked to share the card, so it goes
  /// to Pictures/Ark, where any other app can find it. No permission is
  /// needed for the app's own images on Android 10 and later.
  Future<void> saveToGallery(Uint8List png, int cookieId) async {
    if (!await Gal.hasPermission(toAlbum: true)) {
      await Gal.requestPermission(toAlbum: true);
    }
    await Gal.putImageBytes(png, album: 'Ark', name: 'fortune_$cookieId');
  }

  Future<void> openShareSheet(String path) => SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'image/png')],
      title: 'Share your fortune',
    ),
  );
}
