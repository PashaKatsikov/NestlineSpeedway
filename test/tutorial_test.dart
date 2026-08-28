import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/walkthrough/guide.dart';
import 'package:nestline_circuit/view/widgets/guide_overlay.dart';
import 'package:provider/provider.dart';

import 'support.dart';

Future<Director> bootedGame() async {
  freshSave();
  final game = Director();
  await game.boot();
  return game;
}

/// A screen with two things worth pointing at.
Widget harness({
  required Director game,
  required bool active,
  required VoidCallback onDone,
}) {
  final first = GlobalKey();
  final second = GlobalKey();

  return ChangeNotifierProvider<Director>.value(
    value: game,
    child: MaterialApp(
      theme: Look.dark,
      home: GuideOverlay(
        active: active,
        onDone: onDone,
        steps: [
          GuideBeat(
            anchor: first,
            title: 'The first thing',
            body: 'Look here.',
          ),
          GuideBeat(
            anchor: second,
            title: 'The second thing',
            body: 'Now look here.',
          ),
        ],
        child: Scaffold(
          body: Column(
            children: [
              SizedBox(key: first, width: 100, height: 40),
              SizedBox(key: second, width: 100, height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('lesson progress', () {
    test('every lesson is owed on a fresh save and only once', () async {
      final game = await bootedGame();

      expect(game.needsIntro, isTrue);
      for (final lesson in Guide.values) {
        expect(game.needsGuide(lesson), isTrue, reason: lesson.name);
      }

      game.completeGuide(Guide.race);
      expect(game.needsGuide(Guide.race), isFalse);
      expect(game.needsGuide(Guide.stable), isTrue);

      game.completeIntro();
      expect(game.needsIntro, isFalse);
    });

    test('progress survives a reload', () async {
      final game = await bootedGame();
      game.completeIntro();
      game.completeGuide(Guide.hatchery);

      // completeGuide persists in the background rather than making callers
      // await it, so let the write land before reading it back.
      await pumpEventQueue();

      final reloaded = Director();
      await reloaded.boot();

      expect(reloaded.needsIntro, isFalse);
      expect(reloaded.needsGuide(Guide.hatchery), isFalse);
      expect(reloaded.needsGuide(Guide.race), isTrue);
    });

    test('replaying re-arms everything', () async {
      final game = await bootedGame();
      game.completeIntro();
      for (final lesson in Guide.values) {
        game.completeGuide(lesson);
      }

      game.replayWalkthrough();

      expect(game.needsIntro, isTrue);
      for (final lesson in Guide.values) {
        expect(game.needsGuide(lesson), isTrue, reason: lesson.name);
      }
    });

    test('founding a new stable brings the walkthrough back', () async {
      final game = await bootedGame();
      game.completeIntro();
      game.completeGuide(Guide.stable);

      await game.resetEverything();

      expect(game.needsIntro, isTrue);
      expect(game.needsGuide(Guide.stable), isTrue);
    });
  });

  group('coach overlay', () {
    testWidgets('walks the steps in order and reports back at the end', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(874, 402)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var done = 0;
      final game = await bootedGame();
      await tester.pumpWidget(
        harness(game: game, active: true, onDone: () => done++),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('The first thing'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(done, 0);

      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('The first thing'), findsNothing);
      expect(find.text('The second thing'), findsOneWidget);
      // The last step offers no way out but forward.
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('The second thing'), findsNothing);
      expect(done, 1);
    });

    testWidgets('skipping ends the whole walkthrough', (tester) async {
      tester.view
        ..physicalSize = const Size(874, 402)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var done = 0;
      final game = await bootedGame();
      await tester.pumpWidget(
        harness(game: game, active: true, onDone: () => done++),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('The first thing'), findsNothing);
      expect(find.text('The second thing'), findsNothing);
      expect(done, 1);
    });

    testWidgets('keeps the card on screen beside a full-height anchor', (
      tester,
    ) async {
      const view = Size(667, 375);
      tester.view
        ..physicalSize = view
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tall = GlobalKey();
      final game = await bootedGame();
      await tester.pumpWidget(
        ChangeNotifierProvider<Director>.value(
          value: game,
          child: MaterialApp(
            theme: Look.dark,
            home: GuideOverlay(
              active: true,
              onDone: () {},
              steps: [
                GuideBeat(
                  anchor: tall,
                  title: 'The tall thing',
                  body:
                      'It runs the whole height of the screen, so the card '
                      'has to find room off to one side of it instead.',
                ),
              ],
              // A panel down the left of the screen, as on the hub.
              child: Scaffold(
                body: Row(
                  children: [
                    SizedBox(key: tall, width: 300, height: view.height),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final card = tester.getRect(find.text('The tall thing'));
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.bottom, lessThanOrEqualTo(view.height));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(view.width));
    });

    testWidgets('stays out of the way when the lesson is not owed', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(874, 402)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var done = 0;
      final game = await bootedGame();
      await tester.pumpWidget(
        harness(game: game, active: false, onDone: () => done++),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('The first thing'), findsNothing);
      expect(done, 0);
    });
  });
}
