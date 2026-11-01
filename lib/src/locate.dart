import 'dart:io';

import 'package:path/path.dart' as p;

import 'names.dart';
import 'spec.dart';

/// Where a vendor binary was found, and how.
class Located {
  /// Creates a location.
  Located(this.path, this.via);

  /// Absolute native path of the `.xcframework` directory or `.aar` file.
  final String path;

  /// How it was found, e.g. `\$ACME_WIDGET_SDK_DIR` or `husk_vendor/`.
  final String via;
}

/// The directory named by `--from` or the spec's environment variable, if
/// any, with a label saying which one it was.
///
/// A `--from` path is relative to the working directory; an environment
/// path is relative to [relativeTo], mirroring what the generated build
/// files do.
(String, String)? sourceDir(
  HuskSpec spec,
  Map<String, String> env, {
  String? from,
  required String relativeTo,
}) {
  if (from != null && from.isNotEmpty) {
    return (p.normalize(p.absolute(from)), '--from');
  }
  final value = env[spec.envVar];
  if (value != null && value.isNotEmpty) {
    return (p.normalize(p.join(relativeTo, value)), '\$${spec.envVar}');
  }
  return null;
}

/// Finds the xcframework the way the generated `Package.swift` does.
Located? locateXcframework(
  HuskSpec spec,
  Map<String, String> env, {
  String? from,
  bool includeDropDir = true,
}) {
  final ios = spec.ios;
  if (ios == null) return null;
  final source = sourceDir(
    spec,
    env,
    from: from,
    relativeTo: spec.resolve(ios.packageDir),
  );
  final candidates = [
    if (source != null) (p.join(source.$1, ios.xcframework), source.$2),
    if (includeDropDir)
      (p.join(spec.resolve(ios.dropDir), ios.xcframework), '${ios.dropDir}/'),
  ];
  for (final (path, via) in candidates) {
    if (File(p.join(path, 'Info.plist')).existsSync()) {
      return Located(path, via);
    }
  }
  return null;
}

/// All AARs in [dir] matching the spec's glob, sorted by name.
List<String> matchingAars(HuskSpec spec, String dir) {
  final glob = spec.android?.aar;
  final d = Directory(dir);
  if (glob == null || !d.existsSync()) return const [];
  final pattern = RegExp(globToRegExpSource(glob));
  return [
    for (final e in d.listSync())
      if (e is File && pattern.hasMatch(p.basename(e.path))) e.path,
  ]..sort((a, b) => p.basename(a).compareTo(p.basename(b)));
}

/// Finds the AAR the way the generated `husk.gradle` does (the Gradle
/// property, which only Gradle can read, aside). Returns the chosen file
/// and every other match in the same directory.
(Located, List<String>)? locateAar(
  HuskSpec spec,
  Map<String, String> env, {
  String? from,
  bool includeDropDir = true,
}) {
  final android = spec.android;
  if (android == null || android.aar == null) return null;
  final source = sourceDir(spec, env, from: from, relativeTo: spec.root);
  final dirs = [
    if (source != null) (source.$1, source.$2),
    if (includeDropDir) (spec.resolve(android.dropDir), '${android.dropDir}/'),
  ];
  for (final (dir, via) in dirs) {
    final matches = matchingAars(spec, dir);
    if (matches.isNotEmpty) {
      return (
        Located(matches.last, via),
        matches.sublist(0, matches.length - 1),
      );
    }
  }
  return null;
}
