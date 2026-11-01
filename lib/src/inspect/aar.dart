import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../report.dart';

/// What `doctor` and `check` know about an AAR.
class AarInfo {
  /// Creates the result of [inspectAar].
  AarInfo({
    required this.path,
    required this.findings,
    this.manifestPackage,
    this.versionName,
    this.minSdk,
    this.hasClasses = false,
    this.abis = const [],
    this.fileVersion,
  });

  /// Absolute path of the `.aar` file.
  final String path;

  /// Problems found while reading it.
  final List<Finding> findings;

  /// `package` attribute of its `AndroidManifest.xml`.
  final String? manifestPackage;

  /// `android:versionName` of its manifest, which many libraries omit.
  final String? versionName;

  /// `android:minSdkVersion` of its manifest.
  final String? minSdk;

  /// Whether it contains `classes.jar`.
  final bool hasClasses;

  /// ABIs with native libraries under `jni/`.
  final List<String> abis;

  /// Version parsed from the file name, e.g. `3.2.0` from `x-3.2.0.aar`.
  final String? fileVersion;

  /// Best guess at the library version.
  String? get version => versionName ?? fileVersion;
}

final _fileVersion = RegExp(r'[-_]v?(\d+(?:\.\d+)+(?:[-+][\w.]+)?)\.aar$');

/// Reads the AAR at [path] without extracting it. Never throws for bad
/// input; problems are reported as findings.
AarInfo inspectAar(String path) {
  final findings = <Finding>[];
  final fileVersion = _fileVersion.firstMatch(p.basename(path))?.group(1);
  InputFileStream? input;
  Archive? archive;
  try {
    input = InputFileStream(path);
    archive = ZipDecoder().decodeStream(input);
    if (archive.files.isEmpty) {
      findings.add(
        const Finding(Level.error, 'empty, or not a zip archive (AAR)'),
      );
      return AarInfo(path: path, findings: findings, fileVersion: fileVersion);
    }
    String? package, versionName, minSdk;
    var hasClasses = false;
    final abis = <String>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll(r'\', '/');
      if (name == 'classes.jar') hasClasses = true;
      final jni = RegExp(r'^jni/([^/]+)/[^/]+\.so$').firstMatch(name);
      if (jni != null) abis.add(jni.group(1)!);
      if (name == 'AndroidManifest.xml') {
        if (entry.size > 4 * 1024 * 1024) {
          findings.add(
            const Finding(
              Level.error,
              'AndroidManifest.xml is implausibly large',
            ),
          );
          continue;
        }
        try {
          final doc = XmlDocument.parse(utf8.decode(entry.content));
          final manifest = doc.rootElement;
          package = manifest.getAttribute('package');
          versionName = _androidAttribute(manifest, 'versionName');
          final usesSdk = manifest.findElements('uses-sdk').firstOrNull;
          minSdk = usesSdk == null
              ? null
              : _androidAttribute(usesSdk, 'minSdkVersion');
        } on FormatException catch (e) {
          findings.add(
            Finding(Level.error, 'AndroidManifest.xml: ${e.message}'),
          );
        } on XmlException catch (e) {
          findings.add(
            Finding(Level.error, 'AndroidManifest.xml: ${e.message}'),
          );
        }
      }
    }
    if (!archive.files.any((f) => f.name == 'AndroidManifest.xml')) {
      findings.add(
        const Finding(
          Level.error,
          'no AndroidManifest.xml inside: not an Android library (AAR)',
        ),
      );
    }
    if (!hasClasses) {
      findings.add(
        const Finding(
          Level.warning,
          'no classes.jar inside: the AAR carries no code',
        ),
      );
    }
    return AarInfo(
      path: path,
      findings: findings,
      manifestPackage: package,
      versionName: versionName,
      minSdk: minSdk,
      hasClasses: hasClasses,
      abis: abis.toList()..sort(),
      fileVersion: fileVersion,
    );
  } on Object catch (e) {
    // The zip reader throws a mix of exception types for corrupt input.
    findings.add(Finding(Level.error, 'cannot read as a zip archive: $e'));
    return AarInfo(path: path, findings: findings, fileVersion: fileVersion);
  } finally {
    archive?.clearSync();
    input?.closeSync();
  }
}

const _androidNs = 'http://schemas.android.com/apk/res/android';

String? _androidAttribute(XmlElement element, String local) {
  for (final a in element.attributes) {
    if (a.name.local == local &&
        (a.name.namespaceUri == _androidNs || a.name.prefix == 'android')) {
      return a.value;
    }
  }
  return null;
}
