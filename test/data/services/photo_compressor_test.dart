import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/photo_compressor.dart';
import 'package:image/image.dart' as img;

/// A JPEG with real detail in it, so the compression has something to save.
Uint8List photo(int width, int height, {int orientation = 1}) {
  final random = Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  if (orientation != 1) image.exif.imageIfd.orientation = orientation;
  return img.encodeJpg(image, quality: 100);
}

img.Image read(Uint8List bytes) => img.decodeImage(bytes)!;

void main() {
  test('brings the longest side down to the limit, keeping the shape', () {
    final small = read(shrink(photo(800, 600), maxSide: 400, quality: 80));

    expect(small.width, 400);
    expect(small.height, 300);
  });

  test('a tall photo is limited by its height', () {
    final small = read(shrink(photo(600, 800), maxSide: 400, quality: 80));

    expect(small.width, 300);
    expect(small.height, 400);
  });

  test('a photo already small enough is not blown up', () {
    final same = read(shrink(photo(300, 200), maxSide: 400, quality: 80));

    expect(same.width, 300);
    expect(same.height, 200);
  });

  test('the copy weighs much less than the original', () {
    final original = photo(800, 600);
    final small = shrink(original, maxSide: 400, quality: 80);

    expect(small.length, lessThan(original.length ~/ 3));
  });

  test('a photo rotated in its EXIF arrives upright', () {
    // Orientation 6: stored landscape, meant to be seen turned to portrait.
    final rotated = photo(800, 600, orientation: 6);

    final small = read(shrink(rotated, maxSide: 400, quality: 80));

    expect(small.height, greaterThan(small.width));
  });

  test('a file that is not an image is refused', () {
    expect(
      () => shrink(
        Uint8List.fromList('not a photo'.codeUnits),
        maxSide: 400,
        quality: 80,
      ),
      throwsFormatException,
    );
  });

  test('compressing runs on a background isolate and reads the file there', () async {
    final folder = Directory.systemTemp.createTempSync('compressor_test');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/photo.jpg')
      ..writeAsBytesSync(photo(800, 600));

    final small = await const PhotoCompressor(maxSide: 400).compress(file.path);

    expect(read(small).width, 400);
    // The original on the phone is left as it was.
    expect(read(file.readAsBytesSync()).width, 800);
  });
}
