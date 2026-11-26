import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../models/fortune_model.dart';

/// Draws a fortune as a shareable PNG: the Kotlin app's card, 1080 x 1350,
/// orange to coral, the open cookie holding the paper and the app's name.
///
/// Drawing needs the engine, so it happens here; encoding the PNG is pure CPU
/// work on 1.4 million pixels and runs on a background isolate, so the screen
/// keeps animating while the image is made.
class FortuneCardRenderer {
  const FortuneCardRenderer();

  static const width = 1080;
  static const height = 1350;

  static const _text = Color(0xFF221100);
  static const _cream = Color(0xFFFCEFD5);
  static const _orange = Color(0xFFF8840E);
  static const _coral = Color(0xFFEB5249);
  static const _paperTop = Color(0xFFFFF8EA);
  static const _paperBottom = Color(0xFFFAE3B8);

  /// Each cookie half is drawn 420 px wide, so it is decoded at that size.
  static const _halfSize = 420.0;

  Future<Uint8List> render(Fortune fortune, DateTime day) async {
    final halves = await Future.wait([
      _decode('assets/illustrations/fortune_cookie_left.webp'),
      _decode('assets/illustrations/fortune_cookie_right.webp'),
    ]);
    final figtree = GoogleFonts.figtree().fontFamily;
    await GoogleFonts.pendingFonts();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _draw(canvas, fortune, day, halves[0], halves[1], figtree);
    final image = await recorder.endRecording().toImage(width, height);
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    for (final half in halves) {
      half.dispose();
    }

    // Handed over without a copy; the isolate takes ownership of the bytes.
    final transfer = TransferableTypedData.fromList([pixels!]);
    return Isolate.run(() => _encodePng(transfer), debugName: 'fortune-card');
  }

  static Uint8List _encodePng(TransferableTypedData transfer) {
    final bytes = transfer.materialize();
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes,
      numChannels: 4,
    );
    return img.encodePng(image, level: 6);
  }

  Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _halfSize.round(),
    );
    return (await codec.getNextFrame()).image;
  }

  void _draw(
    Canvas canvas,
    Fortune fortune,
    DateTime day,
    ui.Image left,
    ui.Image right,
    String? figtree,
  ) {
    const w = 1080.0;
    const h = 1350.0;
    final full = const Offset(0, 0) & const Size(w, h);

    // Background: orange to coral, a cream glow behind the cookie, two soft
    // circles in the corners and a few sparkles.
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          colors: [_orange, _coral],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(full),
    );
    canvas.drawRect(
      full,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(w / 2, h * 0.47), w * 0.75, [
          _cream.withValues(alpha: 0.5),
          _cream.withValues(alpha: 0),
        ]),
    );
    final bubble = Paint()..color = _cream.withValues(alpha: 0.11);
    canvas
      ..drawCircle(const Offset(-60, 180), 280, bubble)
      ..drawCircle(const Offset(w + 40, h - 260), 340, bubble);
    final sparkle = Paint()..color = _cream.withValues(alpha: 0.78);
    const sparkles = [
      (150.0, 200.0, 8.0),
      (930.0, 170.0, 7.0),
      (120.0, 1000.0, 6.0),
      (960.0, 1060.0, 9.0),
      (300.0, 140.0, 5.0),
      (780.0, 260.0, 6.0),
      (540.0, 170.0, 7.0),
    ];
    for (final (x, y, r) in sparkles) {
      canvas.drawCircle(Offset(x, y), r, sparkle);
    }

    // The paper, slightly turned, with the phrase, a short rule and the date.
    const centerY = 640.0;
    const paperWidth = 860.0;
    const textWidth = 500.0;
    final quote = _paragraph(
      fortune.quote,
      TextStyle(fontFamily: 'Sorean', fontSize: 50, height: 1.3, color: _text),
      textWidth,
    );
    final date = _paragraph(
      DateFormat('MMMM d, yyyy').format(day),
      TextStyle(
        fontFamily: figtree,
        fontSize: 28,
        color: _text.withValues(alpha: 0.6),
      ),
      textWidth,
    );
    final paperHeight = 70 + quote.height + 26 + 5 + 50 + 50;
    final paper = Rect.fromCenter(
      center: const Offset(w / 2, centerY),
      width: paperWidth,
      height: paperHeight,
    );
    canvas
      ..save()
      ..translate(w / 2, centerY)
      ..rotate(-2 * math.pi / 180)
      ..translate(-w / 2, -centerY);
    final rounded = RRect.fromRectAndRadius(paper, const Radius.circular(10));
    canvas.drawRRect(
      rounded.shift(const Offset(0, 20)),
      Paint()
        ..color = _text.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..shader = ui.Gradient.linear(paper.topCenter, paper.bottomCenter, [
          _paperTop,
          _paperBottom,
        ]),
    );
    canvas.drawParagraph(quote, Offset(w / 2 - textWidth / 2, paper.top + 70));
    final ruleTop = paper.top + 70 + quote.height + 26;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 26, ruleTop, 52, 5),
        const Radius.circular(3),
      ),
      Paint()..color = _orange,
    );
    canvas.drawParagraph(date, Offset(w / 2 - textWidth / 2, ruleTop + 24));
    canvas.restore();

    // The two halves of the cookie, covering the ends of the paper.
    _drawHalf(canvas, left, paper.left + 20, centerY, -1);
    _drawHalf(canvas, right, paper.right - 20, centerY, 1);

    // The app's signature at the bottom.
    final signature = _paragraph(
      'Ark',
      const TextStyle(fontFamily: 'Sorean', fontSize: 64, color: _cream),
      w,
    );
    canvas.drawParagraph(signature, Offset(0, h - 110 - 64));
    final tagline = _paragraph(
      'my fortune cookie of the day',
      TextStyle(
        fontFamily: figtree,
        fontSize: 30,
        color: _cream.withValues(alpha: 0.82),
      ),
      w,
    );
    canvas.drawParagraph(tagline, Offset(0, h - 60 - 30));
  }

  /// One half with its middle at (x, y), tilted outwards, over a soft shadow.
  void _drawHalf(
    Canvas canvas,
    ui.Image half,
    double x,
    double y,
    double side,
  ) {
    const size = _halfSize;
    // Where the middle of the cookie falls inside each half's image.
    final contentX = side < 0 ? 0.30 : 0.63;
    canvas
      ..save()
      ..translate(x, y)
      ..rotate(-side * 16 * math.pi / 180);
    canvas.drawOval(
      Rect.fromLTRB(-size * 0.22, size * 0.36, size * 0.22, size * 0.48),
      Paint()
        ..color = _text.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTRB(
        -contentX * size,
        -0.5 * size,
        (1 - contentX) * size,
        0.5 * size,
      ),
      image: half,
      filterQuality: FilterQuality.medium,
    );
    canvas.restore();
  }

  ui.Paragraph _paragraph(String text, TextStyle style, double width) {
    final builder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(style.getTextStyle())
          ..addText(text);
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }
}
