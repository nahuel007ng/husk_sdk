import 'dart:io';

import 'package:husk_sdk/husk_sdk.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('generate writes every file and a second run changes nothing', () {
    final root = fakePlugin();
    final first = CliRun(root, ['generate']);
    expect(first.exitCode, exitOk, reason: '$first');
    for (final path in [
      'ios/acme_widget/Sources/AcmeWidgetSDKHusk/AcmeWidgetSDKHusk.swift',
      'ios/acme_widget/Sources/acme_widget/AcmeWidgetSDKHuskChannel.swift',
      'android/husk.gradle',
      'android/src/main/kotlin/com/example/acme_widget/AcmeWidgetSDKHuskChannel.kt',
      'android/src/husk/linked/kotlin/com/example/acme_widget/AcmeWidgetSDKHusk.kt',
      'android/src/husk/stub/kotlin/com/example/acme_widget/AcmeWidgetSDKHusk.kt',
      'lib/src/acme_widget_sdk_husk.g.dart',
      '.gitignore',
    ]) {
      expect(exists(root, path), isTrue, reason: path);
    }
    final snapshot = {
      for (final f in Directory(
        root,
      ).listSync(recursive: true).whereType<File>())
        f.path: f.readAsStringSync(),
    };
    final second = CliRun(root, ['generate']);
    expect(second.exitCode, exitOk);
    expect(second.out, isNot(contains('updated')));
    expect(second.out, isNot(contains('created')));
    for (final e in snapshot.entries) {
      expect(File(e.key).readAsStringSync(), e.value, reason: e.key);
    }
  });

  test('owned files carry the generated header', () {
    final root = fakePlugin();
    CliRun(root, ['generate']);
    for (final path in [
      'android/husk.gradle',
      'lib/src/acme_widget_sdk_husk.g.dart',
      'ios/acme_widget/Sources/AcmeWidgetSDKHusk/AcmeWidgetSDKHusk.swift',
    ]) {
      expect(read(root, path), startsWith('// $generatedMarker'), reason: path);
    }
  });

  test('Package.swift gets a self-contained block after the package', () {
    final root = fakePlugin();
    CliRun(root, ['generate']);
    final manifest = read(root, 'ios/acme_widget/Package.swift');
    expect(
      manifest.indexOf('let package = Package('),
      lessThan(manifest.indexOf('BEGIN husk_sdk')),
    );
    expect(manifest, contains('import Foundation'));
    expect(manifest, contains('env["ACME_WIDGET_SDK_DIR"]'));
    expect(manifest, contains('"husk_vendor/AcmeWidgetSDK.xcframework"'));
    expect(
      manifest,
      contains('.binaryTarget(name: "AcmeWidgetSDK", path: path)'),
    );
    expect(manifest, contains('target.name == "acme_widget"'));
    expect(manifest, contains('.define("HUSK_ACMEWIDGETSDK")'));
  });

  test('podspec block sits inside Pod::Spec.new', () {
    final root = fakePlugin();
    CliRun(root, ['generate']);
    final podspec = read(root, 'ios/acme_widget.podspec');
    expect(podspec.trimRight(), endsWith('# END husk_sdk\nend'));
    expect(
      podspec,
      contains("'acme_widget/husk_vendor/AcmeWidgetSDK.xcframework'"),
    );
    expect(
      podspec,
      contains("'acme_widget/Sources/AcmeWidgetSDKHusk/**/*.swift'"),
    );
    expect(podspec, contains('HUSK_ACMEWIDGETSDK'));
  });

  test('Gradle wiring for Kotlin DSL and Groovy', () {
    final kts = fakePlugin();
    CliRun(kts, ['generate']);
    expect(
      read(kts, 'android/build.gradle.kts'),
      contains('apply(from = "husk.gradle")'),
    );
    final groovy = fakePlugin(groovy: true);
    CliRun(groovy, ['generate']);
    expect(
      read(groovy, 'android/build.gradle'),
      contains("apply from: 'husk.gradle'"),
    );
    final script = read(groovy, 'android/husk.gradle');
    expect(script, contains(r'~/^acme\-widget\-.*\.aar$/'));
    expect(script, contains("providers.gradleProperty('acmeWidgetSdkDir')"));
    expect(
      script,
      contains("providers.environmentVariable('ACME_WIDGET_SDK_DIR')"),
    );
    expect(script, contains('flatDir'));
  });

  test('Maven mode wires a repository and coordinates', () {
    final root = fakePlugin(
      spec: '''
sdk: {name: AcmeWidgetSDK}
android:
  maven:
    coordinates: "com.acme:widget:3.2.0"
    username_property: acmeUser
    password_property: acmePassword
''',
    );
    expect(CliRun(root, ['generate']).exitCode, exitOk);
    final script = read(root, 'android/husk.gradle');
    expect(script, contains("implementation 'com.acme:widget:3.2.0'"));
    expect(
      script,
      contains("providers.gradleProperty('acmeWidgetSdkMavenUrl')"),
    );
    expect(script, contains("providers.gradleProperty('acmeUser')"));
    expect(script, contains("providers.gradleProperty('acmePassword')"));
  });

  test('generated Dart pins the expected version and channel', () {
    final root = fakePlugin();
    CliRun(root, ['generate']);
    final dart = read(root, 'lib/src/acme_widget_sdk_husk.g.dart');
    expect(dart, contains('abstract final class AcmeWidgetSdkHusk'));
    expect(dart, contains("static const String expectedVersion = '3.2.0';"));
    expect(dart, contains("MethodChannel('acme_widget/husk')"));
  });

  test('refuses to overwrite a hand-written file without --force', () {
    final root = fakePlugin();
    write(root, 'android/husk.gradle', '// mine\n');
    final run = CliRun(root, ['generate']);
    expect(run.exitCode, exitProblems);
    expect(run.err, contains('not generated by husk_sdk'));
    expect(read(root, 'android/husk.gradle'), '// mine\n');
    expect(CliRun(root, ['generate', '--force']).exitCode, exitOk);
  });

  test('also guards .pubignore when the project has one', () {
    final root = fakePlugin();
    write(root, '.pubignore', 'build/\n');
    CliRun(root, ['generate']);
    expect(read(root, '.pubignore'), contains('/android/husk_vendor/'));
  });

  test('--dry-run reports without writing', () {
    final root = fakePlugin();
    final run = CliRun(root, ['generate', '--dry-run']);
    expect(run.out, contains('would create'));
    expect(exists(root, 'android/husk.gradle'), isFalse);
  });
}
