import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:key_wallet_app/widgets/color_picker_dialog.dart';

void main() {
  group('ColorPickerDialog', () {
    testWidgets('unit test — callback viene chiamato e il dialog si chiude',
            (WidgetTester tester) async {
          Color? selectedColor;

          await tester.pumpWidget(
            MaterialApp(
              home: ColorPickerDialog(
                initialColor: Colors.red,
                onColorChanged: (color) => selectedColor = color,
              ),
            ),
          );

          // Verifica che il titolo e il ColorPicker siano presenti
          expect(find.text('Seleziona un colore'), findsOneWidget);
          expect(find.byType(ColorPicker), findsOneWidget);

          // Simula selezione colore
          final colorPickerWidget = tester.widget<ColorPicker>(find.byType(ColorPicker));
          colorPickerWidget.onColorChanged(Colors.green);
          await tester.pump();

          // Premi OK
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          // Verifica che il callback sia stato chiamato
          expect(selectedColor, equals(Colors.green));
        });

    testWidgets('integration test — mostra e chiude dialog tramite showDialog',
            (WidgetTester tester) async {
          Color? selectedColor;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ColorPickerDialog(
                        initialColor: Colors.blue,
                        onColorChanged: (color) => selectedColor = color,
                      ),
                    );
                  },
                  child: const Text('Apri'),
                ),
              ),
            ),
          );

          // Apri dialog
          await tester.tap(find.text('Apri'));
          await tester.pumpAndSettle();

          // Verifica che il titolo sia presente
          expect(find.text('Seleziona un colore'), findsOneWidget);

          // Simula selezione colore
          final colorPickerWidget = tester.widget<ColorPicker>(find.byType(ColorPicker));
          colorPickerWidget.onColorChanged(Colors.purple);
          await tester.pump();

          // Premi OK
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          // Verifica che il dialog sia chiuso e callback chiamato
          expect(find.text('Seleziona un colore'), findsNothing);
          expect(selectedColor, equals(Colors.purple));
        });
  });
}
