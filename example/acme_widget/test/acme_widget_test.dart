import 'package:acme_widget/acme_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const husk = MethodChannel('acme_widget/husk');
  const plugin = MethodChannel('acme_widget');

  tearDown(() {
    messenger.setMockMethodCallHandler(husk, null);
    messenger.setMockMethodCallHandler(plugin, null);
    AcmeWidgetSdkHusk.resetForTesting();
  });

  test('reports unavailable when no native side answers', () async {
    expect(await AcmeWidget.isSdkAvailable(), isFalse);
    expect(await AcmeWidget.greeting('Ada'), isNull);
  });

  test('reports the stub build', () async {
    messenger.setMockMethodCallHandler(
      husk,
      (call) async => {
        'available': false,
        'platform': 'ios',
        'sdk': 'AcmeWidgetSDK',
      },
    );
    expect(await AcmeWidget.isSdkAvailable(), isFalse);
  });

  test('calls the SDK when it is linked', () async {
    messenger.setMockMethodCallHandler(
      husk,
      (call) async => {
        'available': true,
        'platform': 'ios',
        'sdk': 'AcmeWidgetSDK',
      },
    );
    messenger.setMockMethodCallHandler(
      plugin,
      (call) async => 'Hello ${(call.arguments as Map)['name']}',
    );
    expect(await AcmeWidget.isSdkAvailable(), isTrue);
    expect(await AcmeWidget.greeting('Ada'), 'Hello Ada');
  });
}
