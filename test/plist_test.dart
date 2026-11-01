import 'dart:io';
import 'dart:typed_data';

import 'package:husk_sdk/husk_sdk.dart';
import 'package:test/test.dart';

void main() {
  Map<String, Object?> load(String name) =>
      parsePlist(File('test/fixtures/$name').readAsBytesSync())
          as Map<String, Object?>;

  test('XML and binary encodings of the same plist parse the same', () {
    final xml = load('framework_info.plist');
    final binary = load('framework_info.bplist');
    expect(xml['CFBundleShortVersionString'], '3.2.0');
    expect(xml['UIDeviceFamily'], [1, 2]);
    expect(xml['Retina'], 2.5);
    expect(xml['Signed'], false);
    expect(xml['Unicode'], 'Grüße ✓');
    expect(xml['Blob'], [0, 1, 2]);
    expect(binary, xml);
  });

  group('rejects malformed input without hanging or crashing', () {
    final good = File('test/fixtures/framework_info.bplist').readAsBytesSync();

    test('truncated binary', () {
      expect(
        () => parsePlist(Uint8List.fromList(good.sublist(0, 20))),
        throwsFormatException,
      );
    });

    test('every single-byte corruption of the binary fixture', () {
      for (var i = 0; i < good.length; i++) {
        final bytes = Uint8List.fromList(good)..[i] ^= 0xff;
        try {
          parsePlist(bytes);
        } on FormatException {
          // expected for most positions
        }
      }
    });

    test('cyclic binary plist', () {
      // An array (object 0) whose only element is itself.
      final bytes = BytesBuilder()
        ..add('bplist00'.codeUnits)
        ..add([0xA1, 0x00]) // array of 1, ref 0, at offset 8
        ..add([0x08]) // offset table: object 0 at 8
        ..add([0, 0, 0, 0, 0, 0, 1, 1])
        ..add([0, 0, 0, 0, 0, 0, 0, 1]) // 1 object
        ..add([0, 0, 0, 0, 0, 0, 0, 0]) // top = 0
        ..add([0, 0, 0, 0, 0, 0, 0, 10]); // offset table at 10
      expect(() => parsePlist(bytes.toBytes()), throwsFormatException);
    });

    test('not a plist at all', () {
      expect(
        () => parsePlist(Uint8List.fromList('<html/>'.codeUnits)),
        throwsFormatException,
      );
      expect(
        () => parsePlist(Uint8List.fromList([0xff, 0xfe, 0x00])),
        throwsFormatException,
      );
    });
  });
}
