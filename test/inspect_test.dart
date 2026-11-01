import 'dart:io';

import 'package:husk_sdk/husk_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('xcframework', () {
    test('reads slices, architectures, version and linkage', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      fakeXcframework(path);
      final info = inspectXcframework(path);
      expect(info.findings, isEmpty);
      expect(info.version, '3.2.0');
      expect(info.slices.map((s) => s.platformLabel), ['ios', 'ios simulator']);
      expect(info.slices.last.architectures, ['arm64', 'x86_64']);
      expect(info.slices.map((s) => s.linkage), everyElement(Linkage.static));
    });

    test('detects a dynamic framework', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      fakeXcframework(path, dynamic: true);
      expect(
        inspectXcframework(path).slices.map((s) => s.linkage),
        everyElement(Linkage.dynamic),
      );
    });

    test('a missing simulator slice is an error', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      fakeXcframework(
        path,
        slices: [
          ('ios-arm64', null, ['arm64']),
        ],
      );
      final f = inspectXcframework(path).findings;
      expect(f.single.level, Level.error);
      expect(f.single.message, contains('simulator'));
    });

    test('an x86_64-only simulator slice is a warning', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      fakeXcframework(
        path,
        slices: [
          ('ios-arm64', null, ['arm64']),
          ('ios-x86_64-simulator', 'simulator', ['x86_64']),
        ],
      );
      expect(inspectXcframework(path).findings.single.level, Level.warning);
    });

    test('listed but missing slice directories are errors', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      fakeXcframework(path);
      Directory(p.join(path, 'ios-arm64')).deleteSync(recursive: true);
      final messages = inspectXcframework(path).findings.map((f) => f.message);
      expect(messages, contains(contains('ios-arm64 is listed')));
    });

    test('slice paths that escape the bundle are refused', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      write(
        path,
        'Info.plist',
        xcframeworkPlist([
          ('../../etc', null, ['arm64']),
        ]),
      );
      expect(
        inspectXcframework(path).findings.first.message,
        contains('leaves the xcframework'),
      );
    });

    test('garbage Info.plist is an error, not an exception', () {
      final path = p.join(tempDir().path, 'AcmeWidgetSDK.xcframework');
      write(path, 'Info.plist', 'not a plist');
      expect(inspectXcframework(path).findings.single.level, Level.error);
    });
  });

  group('aar', () {
    test('reads manifest, classes and ABIs', () {
      final path = p.join(tempDir().path, 'acme-widget-3.2.0.aar');
      fakeAar(path, abis: ['arm64-v8a', 'x86_64']);
      final info = inspectAar(path);
      expect(info.findings, isEmpty);
      expect(info.manifestPackage, 'com.acme.widget');
      expect(info.minSdk, '21');
      expect(info.hasClasses, isTrue);
      expect(info.abis, ['arm64-v8a', 'x86_64']);
      expect(info.version, '3.2.0');
    });

    test('versionName wins over the file name', () {
      final path = p.join(tempDir().path, 'acme-widget-3.2.0.aar');
      fakeAar(path, versionName: '3.2.1');
      expect(inspectAar(path).version, '3.2.1');
    });

    test('missing manifest is an error; missing classes a warning', () {
      final path = p.join(tempDir().path, 'acme.aar');
      fakeAar(path, manifest: false, classes: false);
      final levels = inspectAar(path).findings.map((f) => f.level);
      expect(levels, unorderedEquals([Level.error, Level.warning]));
    });

    test('a file that is not a zip is an error, not an exception', () {
      final path = p.join(tempDir().path, 'acme.aar');
      File(path).writeAsStringSync('nope');
      final finding = inspectAar(path).findings.single;
      expect(finding.level, Level.error);
      expect(finding.message, contains('zip'));
    });
  });

  test('detectLinkage looks through a universal binary', () {
    final dir = tempDir().path;
    final fat = File(p.join(dir, 'fat'));
    final header = [
      0xca, 0xfe, 0xba, 0xbe, 0, 0, 0, 1, // magic, 1 arch
      0, 0, 0, 12, 0, 0, 0, 0, // cputype, subtype
      0, 0, 0, 64, 0, 0, 0, 64, // offset 64, size 64
      0, 0, 0, 0, // align
    ];
    fat.writeAsBytesSync([
      ...header,
      ...List.filled(64 - header.length, 0),
      ...dynamicBinary,
    ]);
    expect(detectLinkage(fat), Linkage.dynamic);
    expect(detectLinkage(File(p.join(dir, 'missing'))), Linkage.unknown);
  });
}
