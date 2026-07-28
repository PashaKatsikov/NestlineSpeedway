import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Strips the flat light background from a logo-style PNG and trims it to the
/// remaining artwork.
///
/// Some of the source art arrived with transparency *drawn in* as a light grey
/// checkerboard instead of an actual alpha channel, which reads as an ugly panel
/// behind the logo once it sits on a dark scene. This keys that background out
/// properly: it flood-fills inwards from the border and only eats pixels that
/// are both bright and colourless, so the navy outline of the letters stops it
/// and enclosed white areas such as the chequered flag survive.
///
///   dart run tool/key_out_background.dart assets/brand/logo.png [maxWidth]
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/key_out_background.dart <png> [maxWidth]',
    );
    exit(64);
  }

  final path = args.first;
  final maxWidth = args.length > 1 ? int.parse(args[1]) : 0;

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('no such file: $path');
    exit(66);
  }

  final source = img.decodePng(file.readAsBytesSync());
  if (source == null) {
    stderr.writeln('not a png: $path');
    exit(65);
  }

  final im = source.convert(numChannels: 4);
  final cut = _clearBackground(im);
  final trimmed = _trimToContent(cut) ?? cut;
  final out = (maxWidth > 0 && trimmed.width > maxWidth)
      ? img.copyResize(
          trimmed,
          width: maxWidth,
          interpolation: img.Interpolation.cubic,
        )
      : trimmed;

  file.writeAsBytesSync(img.encodePng(out, level: 9));
  stdout.writeln(
    'keyed $path: ${source.width}x${source.height} -> ${out.width}x${out.height}',
  );
}

/// Brightness above which a pixel can count as background.
const int _minLuma = 176;

/// Channel spread above which a pixel is considered coloured, and so artwork.
const int _maxChroma = 46;

bool _isBackground(img.Pixel p) {
  final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
  final luma = (0.299 * r + 0.587 * g + 0.114 * b).round();
  final chroma = math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
  return luma >= _minLuma && chroma <= _maxChroma;
}

/// Flood-fills the background from every border pixel and clears what it finds.
///
/// Working inwards from the edge is what keeps holes in the artwork opaque; a
/// plain per-pixel brightness test would punch through the white of the
/// chequered flag as well.
img.Image _clearBackground(img.Image im) {
  final w = im.width, h = im.height;
  final open = Uint8List(w * h);
  final queue = <int>[];

  void seed(int x, int y) {
    final i = y * w + x;
    if (open[i] == 1) return;
    if (!_isBackground(im.getPixel(x, y))) return;
    open[i] = 1;
    queue.add(i);
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  while (queue.isNotEmpty) {
    final i = queue.removeLast();
    final x = i % w, y = i ~/ w;
    if (x > 0) seed(x - 1, y);
    if (x < w - 1) seed(x + 1, y);
    if (y > 0) seed(x, y - 1);
    if (y < h - 1) seed(x, y + 1);
  }

  // Clearing the fill leaves a hard staircase where it met the artwork, so any
  // surviving pixel that touches the background gets partial alpha to give the
  // edge back a little softness.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final p = im.getPixel(x, y);
      if (open[i] == 1) {
        im.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      var neighbours = 0;
      if (x > 0 && open[i - 1] == 1) neighbours++;
      if (x < w - 1 && open[i + 1] == 1) neighbours++;
      if (y > 0 && open[i - w] == 1) neighbours++;
      if (y < h - 1 && open[i + w] == 1) neighbours++;
      if (neighbours > 0) {
        final alpha = (255 * (1 - 0.18 * neighbours)).round();
        im.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
      }
    }
  }

  return im;
}

/// Crops away fully transparent margins.
img.Image? _trimToContent(img.Image im) {
  var minX = im.width, minY = im.height, maxX = -1, maxY = -1;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      if (im.getPixel(x, y).a > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return null;
  return img.copyCrop(
    im,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}
