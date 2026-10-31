import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Makes a smaller copy of a photo for uploading; the original on the phone is
/// left untouched.
///
/// Decoding, resizing and re-encoding a camera photo is a second or two of
/// pure CPU work. On the main isolate that is a second or two of frozen
/// screen, so it runs on a background isolate and the UI keeps drawing while
/// it works. The `image` package is plain Dart, which is what makes the
/// isolate do the work instead of just waiting on native code.
class PhotoCompressor {
  const PhotoCompressor({this.maxSide = 1600, this.quality = 80});

  /// Longest side of the copy, in pixels. Big enough for the phone's card,
  /// which is the only place the photo is shown.
  final int maxSide;

  /// JPEG quality of the copy, from 1 to 100.
  final int quality;

  /// The smaller copy of the photo at [path], as JPEG bytes.
  ///
  /// The isolate is handed the path rather than the bytes, so the original
  /// is read there and never copied between isolates. Throws when the file
  /// is not an image this package can read.
  Future<Uint8List> compress(String path) {
    // Locals rather than fields: the closure must not capture `this`.
    final maxSide = this.maxSide;
    final quality = this.quality;
    return Isolate.run(
      () => shrink(
        File(path).readAsBytesSync(),
        maxSide: maxSide,
        quality: quality,
      ),
    );
  }
}

/// The CPU-heavy part, on its own so it can be tested without an isolate.
Uint8List shrink(
  Uint8List original, {
  required int maxSide,
  required int quality,
}) {
  final decoded = img.decodeImage(original);
  if (decoded == null) {
    throw const FormatException('Not an image the app can read.');
  }
  // Cameras often store the rotation in EXIF instead of in the pixels; the
  // copy carries no EXIF, so the rotation is applied to the pixels first or
  // the photo would arrive lying on its side.
  final upright = img.bakeOrientation(decoded);
  final longest = max(upright.width, upright.height);
  final resized = longest <= maxSide
      ? upright
      : img.copyResize(
          upright,
          width: upright.width >= upright.height ? maxSide : null,
          height: upright.height > upright.width ? maxSide : null,
          interpolation: img.Interpolation.average,
        );
  return img.encodeJpg(resized, quality: quality);
}
