import 'dart:io';
import 'package:image/image.dart' as img;

/// Converts all .webp assets into .png inside tool/preview so we can inspect
/// the sprite sheets and slice them correctly. Also prints their dimensions.
void main() {
  final assetsDir = Directory('assets');
  final outDir = Directory('tool/preview');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  for (final entity in assetsDir.listSync(recursive: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.webp')) {
      final bytes = entity.readAsBytesSync();
      final decoded = img.decodeWebP(bytes);
      if (decoded == null) {
        stdout.writeln('FAILED: ${entity.path}');
        continue;
      }
      final name = entity.uri.pathSegments.last.replaceAll('.webp', '.png');
      final outPath = '${outDir.path}/$name';
      File(outPath).writeAsBytesSync(img.encodePng(decoded));
      stdout.writeln('${decoded.width}x${decoded.height}  ->  $outPath');
    }
  }
}
