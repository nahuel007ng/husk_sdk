import 'dart:io';

import 'package:path/path.dart' as p;

import 'spec.dart';

/// Builds the text of a starter `husk.yaml` for the project at [root].
///
/// Only the SDK name and the platforms are set; every other key is written
/// as a comment showing the default that applies, so the file documents
/// itself. Throws [SpecException] when a default cannot be worked out.
String initialSpec(
  String root, {
  required String sdkName,
  String? version,
  String? aar,
  String? androidPackage,
  bool? ios,
  bool? android,
}) {
  final withIos = ios ?? Directory(p.join(root, 'ios')).existsSync();
  final withAndroid =
      android ?? Directory(p.join(root, 'android')).existsSync();
  if (!withIos && !withAndroid) {
    throw SpecException(
      'no ios/ or android/ directory in $root; pass --ios or --android',
    );
  }
  String minimal() {
    final b = StringBuffer('sdk:\n  name: $sdkName\n');
    if (version != null) b.write('  version: $version\n');
    if (withIos) b.write('ios:\n');
    if (withAndroid) {
      b.write('android:\n');
      if (aar != null) b.write("  aar: '$aar'\n");
      if (androidPackage != null) b.write('  package: $androidPackage\n');
    }
    return b.toString();
  }

  // Parsing validates the inputs and computes every default.
  final spec = HuskSpec.parse(minimal(), root: root);
  final b = StringBuffer()
    ..writeln('# husk.yaml: how husk_sdk wires the closed-source $sdkName into')
    ..writeln('# this project. Paths are relative to this file. Commented-out')
    ..writeln(
      '# values show the defaults. Docs: https://pub.dev/packages/husk_sdk',
    )
    ..writeln('sdk:')
    ..writeln('  name: $sdkName')
    ..writeln(
      version == null
          ? '  # version: 1.2.3  # check fails on a mismatch'
          : '  version: $version',
    )
    ..writeln()
    ..writeln('# plugin: ${spec.plugin}')
    ..writeln('# shim: ${spec.shim}')
    ..writeln('# channel: ${spec.channel}')
    ..writeln()
    ..writeln(
      '# Where `link` (and the Gradle build) look for the vendor files.',
    )
    ..writeln('# binary:')
    ..writeln('#   env: ${spec.envVar}')
    ..writeln('#   gradle_property: ${spec.gradleProperty}');
  final i = spec.ios;
  if (i != null) {
    b
      ..writeln()
      ..writeln('ios:')
      ..writeln('  # xcframework: ${i.xcframework}')
      ..writeln('  # package_dir: ${i.packageDir}')
      ..writeln('  # podspec: ${i.podspec ?? 'null  # no podspec found'}')
      ..writeln('  # target: ${i.target}');
  }
  final a = spec.android;
  if (a != null) {
    b
      ..writeln()
      ..writeln('android:')
      ..writeln(aar == null ? "  aar: '*.aar'" : "  aar: '$aar'")
      ..writeln('  # Or, for a private Maven repository instead of a file:')
      ..writeln('  # maven:')
      ..writeln('  #   coordinates: com.example:sdk:1.2.3')
      ..writeln('  # module_dir: ${a.moduleDir}')
      ..writeln(
        androidPackage == null
            ? '  # package: ${a.kotlinPackage}'
            : '  package: $androidPackage',
      )
      ..writeln('  # source_dir: ${a.sourceDir}');
  }
  b
    ..writeln()
    ..writeln('# dart:')
    ..writeln('#   output: ${spec.dart.output}')
    ..writeln('#   class: ${spec.dart.className}');
  final text = b.toString();
  // The written file must parse to the same spec.
  HuskSpec.parse(text, root: root);
  return text;
}
