import 'package:husk_sdk/src/names.dart';
import 'package:test/test.dart';

void main() {
  test('splitWords handles acronyms, snake case and camel case', () {
    expect(splitWords('AcmeWidgetSDK'), ['acme', 'widget', 'sdk']);
    expect(splitWords('SDKWidget'), ['sdk', 'widget']);
    expect(splitWords('acme_widget_sdk'), ['acme', 'widget', 'sdk']);
    expect(splitWords('acmeWidget2Sdk'), ['acme', 'widget2', 'sdk']);
  });

  test('case conversions', () {
    final w = splitWords('AcmeWidgetSDK');
    expect(snake(w), 'acme_widget_sdk');
    expect(screamingSnake(w), 'ACME_WIDGET_SDK');
    expect(upperCamel(w), 'AcmeWidgetSdk');
    expect(lowerCamel(w), 'acmeWidgetSdk');
  });

  test('globToRegExpSource escapes everything but * and ?', () {
    final r = RegExp(globToRegExpSource('acme-widget-*.aar'));
    expect(r.hasMatch('acme-widget-3.2.0.aar'), isTrue);
    expect(r.hasMatch('acme-widget-.aar'), isTrue);
    expect(r.hasMatch('acme-widgetX3.aar'), isFalse);
    expect(r.hasMatch('acme-widget-3.2.0.aar.bak'), isFalse);
    expect(RegExp(globToRegExpSource('a?.aar')).hasMatch('ab.aar'), isTrue);
    expect(globToRegExpSource('x+y.aar'), r'^x\+y\.aar$');
  });
}
