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

  testWidgets('dragging the disc onto a column drops a piece', (tester) async {
    await tester.pumpWidget(const ConnectFourApp());
    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();

    final disc = find.byKey(const Key('disc-tray'));
    final column3 = find.byKey(const Key('drop-3'));
    expect(disc, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(disc));
    await tester.pump(const Duration(milliseconds: 20));
    // Nudge to start the drag, which flips the board into drop mode.
    await gesture.moveTo(tester.getCenter(disc) + const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(column3));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Player 1's disc landed, so it is now player 2's turn.
    expect(find.text("Player 2's turn"), findsOneWidget);
  });

  testWidgets('disc tray is disabled once the game is over', (tester) async {
    await tester.pumpWidget(const ConnectFourApp());
    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();

    // Player 1 wins with four in column 0; player 2 replies in column 1.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('cell-0-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cell-0-1')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.text('Player 1 wins!'), findsOneWidget);
    expect(find.text('Tap a column to drop'), findsOneWidget);
  });
}
