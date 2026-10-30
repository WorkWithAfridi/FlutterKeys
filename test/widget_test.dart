import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_keys/main.dart';

void main() {
  for (final keyed in [false, true]) {
    testWidgets(
      'cart quantity ${keyed ? 'follows product' : 'follows position'}',
      (tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.tap(find.text(keyed ? 'With keys' : 'Without keys'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add Everyday Tote'));
        await tester.pump();
        await tester.tap(find.text('Sort by price'));
        await tester.pump();
        final tile = tester.widget<CartTile>(find.byType(CartTile).first);
        expect(tile.product.name, 'Classic Wallet');
        expect(
          find.descendant(
            of: find.byType(CartTile).first,
            matching: find.textContaining('Quantity: ${keyed ? 1 : 2}'),
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets('preview reset ${keyed ? 'replaces' : 'retains'} state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: LabPage(keyed: keyed)));
      await tester.ensureVisible(find.text('Start new preview'));
      await tester.pumpAndSettle();
      final preview = find.byType(ProductPreview).first;
      await tester.tap(
        find.descendant(of: preview, matching: find.byType(CheckboxListTile)),
      );
      await tester.pump();
      await tester.tap(find.text('Rebuild parent'));
      await tester.pump();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.descendant(
                of: preview,
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.text('Start new preview'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.descendant(
                of: preview,
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        !keyed,
      );
    });
    testWidgets('moving preview ${keyed ? 'preserves' : 'resets'} state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: LabPage(keyed: keyed)));
      await tester.ensureVisible(find.text('Floating preview'));
      await tester.pumpAndSettle();
      final moving = find.byType(ProductPreview).last;
      await tester.tap(
        find.descendant(of: moving, matching: find.byType(CheckboxListTile)),
      );
      await tester.pump();
      await tester.tap(find.text('Floating preview'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.descendant(
                of: find.byType(ProductPreview).last,
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        keyed,
      );
    });
  }
}
