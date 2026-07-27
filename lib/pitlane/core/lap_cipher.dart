import 'dart:typed_data';

/// Position-keyed additive cipher over an FNV-1a-seeded LCG keystream.
/// The salt below is unique to this app; regenerate every byte array in
/// [PitwallConfig] via `dart run tool/encode_pit_values.dart` after changing it.
const List<int> _gridSalt = <int>[
  0x4E,
  0x73,
  0x57,
  0x7E,
  0x50,
  0x69,
  0x74,
  0x4C,
  0x61,
  0x6E,
  0x65,
  0x7E,
  0x32,
  0x36,
];

int _seedFromGrid() {
  var hash = 0x811c9dc5;
  for (final byte in _gridSalt) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0xffffffff;
}

Uint8List _lapStream(int length) {
  var state = _seedFromGrid();
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    state = (state * 1103515245 + 12345) & 0xffffffff;
    out[i] = (state >> 16) & 0xff;
  }
  return out;
}

/// Decodes a byte array produced by `tool/encode_pit_values.dart`.
String unmaskLap(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final stream = _lapStream(encoded.length);
  final plain = Uint8List(encoded.length);
  for (var i = 0; i < encoded.length; i++) {
    plain[i] = (encoded[i] - stream[i] - (i * 13)) & 0xff;
  }
  return String.fromCharCodes(plain);
}
