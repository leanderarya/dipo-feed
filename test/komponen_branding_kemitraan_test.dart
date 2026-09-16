import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dipo_feed/core/constants/partnership_constants.dart';
import 'package:dipo_feed/core/widgets/partnership_branding_widget.dart';
import 'package:dipo_feed/core/widgets/partnership_info_dialog.dart';
import 'package:dipo_feed/features/home/home_screen.dart';

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
      expect(find.text('UNDIP'), findsOneWidget);
      expect(find.text('ACIAR'), findsOneWidget);
      expect(find.text('DipoFeed'), findsOneWidget);
      expect(find.text(PartnershipConstants.introText), findsOneWidget);

      // Tap Close button
      final closeButton = find.text('Tutup');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify Dialog is dismissed
      expect(find.text('Kerja Sama Kemitraan'), findsNothing);
    });
  });

  group('HomeScreen Header Capsule Tests', () {
    testWidgets(
      'renders partnership capsule on left and opens dialog on tap',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify left partnership capsule logo is present
        final aciarLogoFinder = find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/logo_aciar.png');
        expect(aciarLogoFinder, findsOneWidget);

        // Verify right DipoFeed brand logo is present
        final dipoLogoFinder = find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/DIPOFeed.png');
        expect(dipoLogoFinder, findsOneWidget);

        // Verify left capsule is positioned before right capsule
        final aciarOffset = tester.getTopLeft(aciarLogoFinder);
        final dipoOffset = tester.getTopLeft(dipoLogoFinder);
        expect(aciarOffset.dx, lessThan(dipoOffset.dx));

        // Tap left partnership capsule
        await tester.tap(aciarLogoFinder);
        await tester.pumpAndSettle();

        // Verify partnership info dialog opens
        expect(find.text('Kerja Sama Kemitraan'), findsOneWidget);
        expect(find.text('UNDIP & ACIAR Australia'), findsOneWidget);
      },
    );
  });
}
