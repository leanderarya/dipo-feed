import 'package:flutter_test/flutter_test.dart';

import 'package:dipo_feed/app.dart';

void main() {
  testWidgets('Home screen shows main Dipo Feed menus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DipoFeedApp());
    await tester.pumpAndSettle();

    expect(find.text('Cek Kecukupan Pakan'), findsOneWidget);
    expect(find.text('Master Bahan Pakan'), findsOneWidget);
    expect(find.text('Cek Kandungan Nutrisi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Simulator Formulasi Ransum'),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.text('Simulator Formulasi Ransum'), findsOneWidget);
  });
}
