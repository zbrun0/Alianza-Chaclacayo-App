import 'package:flutter_test/flutter_test.dart';
import 'package:alianza_chaclacayo_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(find.byType(AlianzaChaclacayoApp), findsNothing);
  });
}
