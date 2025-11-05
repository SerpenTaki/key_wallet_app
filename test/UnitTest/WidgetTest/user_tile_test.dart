import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';

void main() {
  group("User Tile", () {

    testWidgets('Mostra User Tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserTile(
            text: "Test",
            subtext: "SubText",
            color: Colors.black,
            onTap: () {  },
          )
        )
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text("Test"), findsOneWidget);
      expect(find.text("SubText"), findsOneWidget);
      if(defaultTargetPlatform == TargetPlatform.android){
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      }else{
        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      }
    });

  });
}