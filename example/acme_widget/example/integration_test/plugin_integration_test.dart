import 'package:acme_widget/acme_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pass --dart-define=EXPECT_SDK=true when the build links AcmeWidgetSDK.
const expectSdk = bool.fromEnvironment('EXPECT_SDK');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports whether AcmeWidgetSDK is linked', (tester) async {
    expect(await AcmeWidget.isSdkAvailable(), expectSdk);
    final greeting = await AcmeWidget.greeting('husk_sdk');
    if (expectSdk) {
      expect(greeting, 'Hello husk_sdk, from AcmeWidgetSDK 3.2.0');
    } else {
      expect(greeting, isNull);
    }
  });
}
