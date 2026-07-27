// ignore_for_file: avoid_print

import 'dart:typed_data';

// Keep this salt byte-identical with lib/pitlane/core/lap_cipher.dart.
// Unique per project — do NOT reuse across sibling apps.
const List<int> _gridSalt = <int>[
  0x4E, // N
  0x73, // s
  0x57, // W
  0x7E, // ~
  0x50, // P
  0x69, // i
  0x74, // t
  0x4C, // L
  0x61, // a
  0x6E, // n
  0x65, // e
  0x7E, // ~
  0x32, // 2
  0x36, // 6
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

List<int> mask(String value) {
  final bytes = Uint8List.fromList(value.codeUnits);
  final stream = _lapStream(bytes.length);
  return List<int>.generate(
    bytes.length,
    (i) => (bytes[i] + stream[i] + (i * 13)) & 0xff,
  );
}

String unmask(List<int> encoded) {
  final stream = _lapStream(encoded.length);
  return String.fromCharCodes(
    List<int>.generate(
      encoded.length,
      (i) => (encoded[i] - stream[i] - (i * 13)) & 0xff,
    ),
  );
}

void main() {
  const values = <String, String>{
    'config': 'https://nestlinnespeedway.com/config.php',
    'privacy': 'https://nestlinnespeedway.com/privacy-policy.html',
    'support': 'https://nestlinnespeedway.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.5',
    'safariTail': '604.1',
    'appsFlyerDevKey': '3UD445feocppboA2CbzDSk',
    'firebaseProjectNumber': '573977146660',
    'oneLinkHost': 'nestlinespeedway.onelink.me',
  };

  for (final entry in values.entries) {
    final encoded = mask(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    if (unmask(encoded) != entry.value) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  print('VERIFY: all values round-tripped');
}
