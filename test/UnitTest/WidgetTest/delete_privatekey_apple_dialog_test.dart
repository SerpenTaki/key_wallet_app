import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/keys_dialogs/delete_privatekey_apple_dialog.dart';

void main() {
  testWidgets("Mostra titolo, contenuto e pulsanti", (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeletePrivatekeyAppleDialog(),
      ),
    );

    expect(find.text("Elimina chiave privata dal dispositivo"), findsOneWidget);
    expect(
      find.text(
        "Sei sicuro di voler eliminare la chiave privata dal dispositivo? Assicurati di essertela segnata",
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key("Annulla")), findsOneWidget);
    expect(find.byKey(const Key("Elimina")), findsOneWidget);
  });

  testWidgets("Clic su Annulla chiude il dialog con false", (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DeletePrivatekeyAppleDialog(),
              );
            },
            child: const Text("Apri Dialog"),
          ),
        ),
      ),
    );

    // Apri il dialog
    await tester.tap(find.text("Apri Dialog"));
    await tester.pumpAndSettle();

    // Premi "Annulla"
    await tester.tap(find.byKey(const Key("Annulla")));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets("Clic su Elimina chiude il dialog con true", (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DeletePrivatekeyAppleDialog(),
              );
            },
            child: const Text("Apri Dialog"),
          ),
        ),
      ),
    );

    // Apri il dialog
    await tester.tap(find.text("Apri Dialog"));
    await tester.pumpAndSettle();

    // Premi "Elimina"
    await tester.tap(find.byKey(const Key("Elimina")));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}

