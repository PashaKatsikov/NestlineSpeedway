import 'dart:io';
import 'package:image/image.dart' as img;

void probe(String path) {
  final bytes = File(path).readAsBytesSync();
  final im = img.decodeWebP(bytes)!;
  int transparent = 0;
  int nearWhiteOpaque = 0;
  final total = im.width * im.height;
  for (final p in im) {
    if (p.a < 10) {
      transparent++;
    } else if (p.r > 240 && p.g > 240 && p.b > 240) {
      nearWhiteOpaque++;
    }
  }
  final c = im.getPixel(0, 0);
  stdout.writeln(
      '$path  ${im.width}x${im.height} corner=(${c.r},${c.g},${c.b},${c.a}) '
      'transparent=${(transparent / total * 100).toStringAsFixed(1)}% '
      'nearWhiteOpaque=${(nearWhiteOpaque / total * 100).toStringAsFixed(1)}%');
}

void main() {
  const base = 'assets/Nestline_Speedway_gameplay_assets';
  for (final f in [
    'chicken_asset',
    'eggs_asset',
    'foods_asset',
    'decorative_chicken_feathers_asset',
    'wearable_accessories_variant2_asset',
  ]) {
    probe('$base/$f.webp');
  }
}
