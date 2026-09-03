import 'package:connect_four/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home offers both modes', (tester) async {
    await tester.pumpWidget(const ConnectFourApp());
    expect(find.text('FOURWARD'), findsOneWidget);
    expect(find.text('Play vs Bot'), findsOneWidget);
    expect(find.text('Two Players'), findsOneWidget);
  });

  testWidgets('two-player game alternates and restarts', (tester) async {
    await tester.pumpWidget(const ConnectFourApp());
    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();
    expect(find.text("Player 1's turn"), findsOneWidget);
    await tester.tap(find.byKey(const Key('cell-0-0')));
    await tester.pump();
    expect(find.text("Player 2's turn"), findsOneWidget);
    await tester.tap(find.text('RESTART ROUND'));
    await tester.pump();
    expect(find.text("Player 1's turn"), findsOneWidget);
  });
}
