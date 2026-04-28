import 'package:flutter_test/flutter_test.dart';

import 'package:dipo_feed/app.dart';

void main() {
  testWidgets('Home screen shows primary home content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DipoFeedApp());
    await tester.pumpAndSettle();

    expect(find.text('Cek Kecukupan'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Panduan'), findsOneWidget);
  });
}
