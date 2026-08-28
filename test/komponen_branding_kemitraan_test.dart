import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dipo_feed/core/widgets/partnership_branding_widget.dart';
import 'package:dipo_feed/core/widgets/partnership_info_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PartnershipBrandingWidget Tests', () {
    testWidgets('renders partnership branding widget in card mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PartnershipBrandingWidget(
                height: 38,
                isCardStyle: true,
                showInfoBadge: true,
              ),
            ),
          ),
        ),
      );

      // Verify that the images or fallback widgets are rendered
      expect(find.byType(PartnershipBrandingWidget), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PartnershipBrandingWidget(
                height: 38,
                isCardStyle: true,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PartnershipBrandingWidget));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('PartnershipInfoDialog Tests', () {
    testWidgets('displays dialog content and closes on Tutup tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => PartnershipInfoDialog.show(context),
                  child: const Text('Buka Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Verify Dialog header and contents
      expect(find.text('Kerja Sama Kemitraan'), findsOneWidget);
      expect(find.text('UNDIP & ACIAR Australia'), findsOneWidget);
      expect(find.text('Universitas Diponegoro (UNDIP)'), findsOneWidget);
      expect(find.text('ACIAR Australia'), findsOneWidget);
      expect(find.text('Inovasi DipoFeed'), findsOneWidget);

      // Tap Close button
      final closeButton = find.text('Tutup');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify Dialog is dismissed
      expect(find.text('Kerja Sama Kemitraan'), findsNothing);
    });
  });
}
