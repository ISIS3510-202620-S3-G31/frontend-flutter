import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A photo file decoded only as large as the box it covers, not at the size
/// of the file.
///
/// A photo picked from the gallery arrives up to 2048 pixels wide, often
/// 1836 x 4080, and decoding it whole takes 1836 * 4080 * 4 bytes, about
/// 30 MB, for a card that needs under 5 MB. Flutter keeps decoded images in
/// its image cache, so a few of them fill it and push each other out.
///
/// The target size is worked out from the photo's own size when it is
/// decoded, so the result still covers the box (as [BoxFit.cover] needs)
/// whatever the photo's shape.
@immutable
class CoverSizedImage extends ImageProvider<CoverSizedImage> {
  const CoverSizedImage(this.file, {required this.box});

  final File file;

  /// The box to cover, in physical pixels.
  final Size box;

  /// The size to decode an image of [width] x [height] so that it covers
  /// [box], as [BoxFit.cover] would scale it. Never larger than the image
  /// itself.
  static ui.TargetImageSize coverSize(int width, int height, Size box) {
    final scale = math.max(box.width / width, box.height / height);
    if (scale >= 1) return ui.TargetImageSize(width: width, height: height);
    return ui.TargetImageSize(
      width: _atLeast(width * scale),
      height: _atLeast(height * scale),
    );
  }

  /// Rounds up, so the image never falls a pixel short of the box, but not
  /// past a value that is only off by floating point (948.0000001 is 948).
  static int _atLeast(double pixels) => (pixels - 1e-6).ceil();

  @override
  Future<CoverSizedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CoverSizedImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _decode(decode),
    scale: 1,
    debugLabel: file.path,
  );

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    // Read straight from the file, without copying it into Dart first.
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    return decode(
      buffer,
      getTargetSize: (width, height) => coverSize(width, height, box),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoverSizedImage &&
      other.file.path == file.path &&
      other.box == box;

  @override
  int get hashCode => Object.hash(file.path, box);
}

/// A file shown with [BoxFit.cover], decoded at the size it is drawn.
class CoverFileImage extends StatelessWidget {
  const CoverFileImage(this.file, {super.key});

  final File file;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Without a bounded box there is nothing to size it to.
        final ImageProvider image =
            constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? CoverSizedImage(file, box: constraints.biggest * ratio)
            : FileImage(file);
        return Image(image: image, fit: BoxFit.cover);
      },
    );
  }
}
