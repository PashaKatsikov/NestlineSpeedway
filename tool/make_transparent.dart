import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates a fully transparent PNG used as the adaptive-icon foreground so
/// that the full-bleed Icon.png (used as the adaptive background) fills the
/// entire icon surface with no empty edges.
void main() {
  final dir = Directory('assets/gen/misc')..createSync(recursive: true);
  final im = img.Image(width: 512, height: 512, numChannels: 4);
  img.fill(im, color: img.ColorRgba8(0, 0, 0, 0));
  File('${dir.path}/transparent.png').writeAsBytesSync(img.encodePng(im));
  stdout.writeln('wrote ${dir.path}/transparent.png');
}
