import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/chatWidgets/chat_bubble.dart';

void main(){
  testWidgets("ChatBubble test isCurrentUser == true", (WidgetTester tester) async{
    await tester.pumpWidget(
      MaterialApp(
        home: ChatBubble(
          message: "Hello",
          isCurrentUser: true,
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final boxDecoration = container.decoration as BoxDecoration;

    expect(find.text("Hello"), findsOneWidget);
    expect(boxDecoration.borderRadius, BorderRadius.circular(12));


    final theme = ThemeData();
    expect(boxDecoration.color, theme.colorScheme.primary);
  });

  testWidgets("ChatBubble test isCurrentUser == false", (WidgetTester tester) async{
    await tester.pumpWidget(
      MaterialApp(
        home: ChatBubble(
          message: "Hello",
          isCurrentUser: false,
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final boxDecoration = container.decoration as BoxDecoration;

    expect(find.text("Hello"), findsOneWidget);
    expect(boxDecoration.borderRadius, BorderRadius.circular(12));


    final theme = ThemeData();
    expect(boxDecoration.color, theme.colorScheme.secondary);
  });
}