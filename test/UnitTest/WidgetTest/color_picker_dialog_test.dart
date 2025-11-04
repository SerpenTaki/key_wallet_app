import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:key_wallet_app/widgets/color_picker_dialog.dart';

void main() {
  testWidgets('Mostra il dialog e cambia colore', (WidgetTester tester) async {
    Color? selectedColor;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initialColor: Colors.red,
                    onColorChanged: (color) => selectedColor = color,
                  ),
                );
              },
              child: const Text('Apri dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Seleziona un colore'), findsOneWidget);

    expect(find.byType(ColorPicker), findsOneWidget);

    final ColorPicker pickerWidget = tester.widget<ColorPicker>(find.byType(ColorPicker));
    pickerWidget.onColorChanged(Colors.blue);
    await tester.pump();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    expect(selectedColor, equals(Colors.blue));
  });
}
