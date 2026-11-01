import 'package:husk_sdk/husk_sdk.dart';
import 'package:test/test.dart';

import 'support.dart';

HuskSpec parse(String yaml, {String? root}) =>
    HuskSpec.parse(yaml, root: root ?? fakePlugin());

Matcher throwsSpec(String fragment) => throwsA(
  isA<SpecException>().having((e) => e.message, 'message', contains(fragment)),
);

void main() {
  test('derives every default from the SDK name and the project', () {
    final spec = parse(acmeSpec);
    expect(spec.sdkName, 'AcmeWidgetSDK');
    expect(spec.version, '3.2.0');
    expect(spec.plugin, 'acme_widget');
    expect(spec.shim, 'AcmeWidgetSDKHusk');
    expect(spec.channel, 'acme_widget/husk');
    expect(spec.envVar, 'ACME_WIDGET_SDK_DIR');
    expect(spec.gradleProperty, 'acmeWidgetSdkDir');
    expect(spec.defineName, 'HUSK_ACMEWIDGETSDK');
    expect(spec.ios!.xcframework, 'AcmeWidgetSDK.xcframework');
    expect(spec.ios!.packageDir, 'ios/acme_widget');
    expect(spec.ios!.podspec, 'ios/acme_widget.podspec');
    expect(spec.ios!.target, 'acme_widget');
    expect(spec.ios!.dropDir, 'ios/acme_widget/husk_vendor');
    expect(spec.android!.aar, 'acme-widget-*.aar');
    expect(spec.android!.kotlinPackage, 'com.example.acme_widget');
    expect(spec.android!.dropDir, 'android/husk_vendor');
    expect(spec.dart.output, 'lib/src/acme_widget_sdk_husk.g.dart');
    expect(spec.dart.className, 'AcmeWidgetSdkHusk');
  });

  test('reads the namespace from a Groovy build file', () {
    final root = fakePlugin(groovy: true);
    expect(
      parse(acmeSpec, root: root).android!.kotlinPackage,
      'com.example.acme_widget',
    );
  });

  test('platforms are opt-in', () {
    final spec = parse('sdk:\n  name: AcmeWidgetSDK\nandroid:\n');
    expect(spec.ios, isNull);
    expect(spec.android!.aar, '*.aar');
    expect(
      () => parse('sdk:\n  name: AcmeWidgetSDK\n'),
      throwsSpec('at least one of'),
    );
  });

  test('podspec: null skips CocoaPods', () {
    final spec = parse('sdk: {name: AcmeWidgetSDK}\nios:\n  podspec: null\n');
    expect(spec.ios!.podspec, isNull);
  });

  test('rejects unknown keys with the allowed list', () {
    expect(
      () => parse(
        'sdk: {name: AcmeWidgetSDK}\nios:\n  xcframwork: X.xcframework\n',
      ),
      throwsSpec('ios.xcframwork: unknown key'),
    );
  });

  test('rejects values that would need escaping in generated code', () {
    expect(
      () => parse('sdk: {name: "Acme\\"SDK"}\nios:\n'),
      throwsSpec('sdk.name'),
    );
    expect(
      () => parse('sdk: {name: AcmeWidgetSDK}\nbinary: {env: "A B"}\nios:\n'),
      throwsSpec('binary.env'),
    );
    expect(
      () => parse('sdk: {name: AcmeWidgetSDK}\nandroid: {aar: "../x.aar"}\n'),
      throwsSpec('android.aar'),
    );
  });

  test('paths must stay inside the project; backslashes are separators', () {
    expect(
      () => parse('sdk: {name: AcmeWidgetSDK}\nios: {package_dir: /abs}\n'),
      throwsSpec('relative'),
    );
    expect(
      () =>
          parse('sdk: {name: AcmeWidgetSDK}\nios: {package_dir: "C:\\\\x"}\n'),
      throwsSpec('relative'),
    );
    expect(
      () => parse('sdk: {name: AcmeWidgetSDK}\nios: {package_dir: ../out}\n'),
      throwsSpec('inside the project'),
    );
    final spec = parse(
      'sdk: {name: AcmeWidgetSDK}\nios: {package_dir: "ios\\\\acme_widget"}\n',
    );
    expect(spec.ios!.packageDir, 'ios/acme_widget');
  });

  test('aar and maven are exclusive', () {
    expect(
      () => parse('''
sdk: {name: AcmeWidgetSDK}
android:
  aar: x.aar
  maven: {coordinates: "com.acme:widget:3.2.0"}
'''),
      throwsSpec('either aar or maven'),
    );
  });

  test('maven defaults', () {
    final spec = parse('''
sdk: {name: AcmeWidgetSDK}
android:
  maven: {coordinates: "com.acme:widget:3.2.0"}
''');
    final maven = spec.android!.maven!;
    expect(spec.android!.aar, isNull);
    expect(maven.urlProperty, 'acmeWidgetSdkMavenUrl');
    expect(maven.urlEnv, 'ACME_WIDGET_SDK_MAVEN_URL');
  });

  test('missing android package without a namespace is an error', () {
    final root = tempDir().path;
    write(root, 'pubspec.yaml', 'name: acme_widget\n');
    write(root, 'android/build.gradle.kts', 'plugins {}\n');
    expect(
      () => HuskSpec.parse('sdk: {name: X}\nandroid:\n', root: root),
      throwsSpec('android.package'),
    );
  });

  test('invalid YAML is a SpecException', () {
    expect(() => parse('sdk: [\n'), throwsA(isA<SpecException>()));
  });
}
