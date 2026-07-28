import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support.dart';

import 'package:nestline_speedway/core/theme.dart';
import 'package:nestline_speedway/race/race_engine.dart';
import 'package:nestline_speedway/season/season_map.dart';
import 'package:nestline_speedway/state/game.dart';
import 'package:nestline_speedway/ui/screens/about_screen.dart';
import 'package:nestline_speedway/ui/screens/codex_screen.dart';
import 'package:nestline_speedway/ui/screens/flock_screen.dart';
import 'package:nestline_speedway/tutorial/lesson.dart';
import 'package:nestline_speedway/ui/screens/hatchery_screen.dart';
import 'package:nestline_speedway/ui/screens/intro_screen.dart';
import 'package:nestline_speedway/ui/screens/loading_screen.dart';
import 'package:nestline_speedway/ui/screens/race_screen.dart';
import 'package:nestline_speedway/ui/screens/rest_screen.dart';
import 'package:nestline_speedway/ui/screens/result_screen.dart';
import 'package:nestline_speedway/ui/screens/season_screen.dart';
import 'package:nestline_speedway/ui/screens/settings_screen.dart';
import 'package:nestline_speedway/ui/screens/stable_screen.dart';
import 'package:nestline_speedway/ui/screens/title_screen.dart';
import 'package:nestline_speedway/ui/screens/trader_screen.dart';
import 'package:nestline_speedway/ui/screens/training_screen.dart';
import 'package:nestline_speedway/ui/screens/upgrades_screen.dart';

/// The game is landscape-only, so these are the shapes it actually has to
/// survive: the shortest phone we support, a current phone, and an iPad.
const Map<String, Size> _viewports = {
  'small phone': Size(667, 375),
  'phone': Size(874, 402),
  'tablet': Size(1210, 834),
};

/// The loading screen is the one place that also has to work upright, since the
/// game does not lock to landscape until it has finished starting up.
const Map<String, Size> _portraitViewports = {
  'small phone upright': Size(375, 667),
  'phone upright': Size(402, 874),
  'tablet upright': Size(834, 1210),
};

Future<Game> _bootedGame() async {
  freshSave();
  final game = Game();
  await game.boot();
  // Screens are tested bare by default. The walkthrough draws over the top of
  // them, so it gets its own set of cases rather than colouring every one.
  game.stable.introSeen = true;
  for (final lesson in Lesson.values) {
    game.completeLesson(lesson);
  }
  return game;
}

/// Re-arms one walkthrough so the screen builds with its coach marks showing.
void _teach(Game game, Lesson lesson) =>
    game.stable.lessonsSeen.remove(lesson.name);

Future<void> _show(WidgetTester tester, Game game, Widget screen) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<Game>.value(
      value: game,
      child: MaterialApp(theme: AppTheme.dark, home: screen),
    ),
  );
  await tester.pump(const Duration(milliseconds: 350));
}

/// Registers one test per screen per viewport.
///
/// `pumpWidget` surfaces layout overflow as a test failure, so simply building
/// each screen at each size is enough to catch the clipping that a landscape-only
/// game is prone to. [prepare] puts the game into whatever state the screen needs
/// to have something to draw.
void screenTest(
  String name,
  Widget Function() build, {
  void Function(Game game)? prepare,
  Map<String, Size> viewports = _viewports,
}) {
  group(name, () {
    for (final entry in viewports.entries) {
      testWidgets('lays out on a ${entry.key}', (tester) async {
        tester.view
          ..physicalSize = entry.value
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final game = await _bootedGame();
        prepare?.call(game);
        await _show(tester, game, build());

        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// Puts the game into a live season with the whole stable entered.
void _inSeason(Game game) {
  game.startSeason(game.stable.racers.map((r) => r.id).toList());
}

/// Walks the schedule until it reaches a node of [kind] so the encounter screens
/// have real content to render.
///
/// Row 0 is always the opening sprint and the map is randomised, so this steps
/// forward node by node and starts a fresh season if a route runs out.
void _atNode(Game game, NodeKind kind) {
  for (var attempt = 0; attempt < 60; attempt++) {
    _inSeason(game);
    final season = game.season!;
    while (season.available.isNotEmpty) {
      final wanted = season.available.where((n) => n.kind == kind).firstOrNull;
      if (wanted != null) {
        game.travelTo(wanted);
        return;
      }
      game.travelTo(season.available.first);
    }
  }
  fail('no $kind node was reachable in 60 generated seasons');
}

void main() {
  screenTest('loading', () => const LoadingScreen());
  screenTest(
    'loading upright',
    () => const LoadingScreen(),
    viewports: _portraitViewports,
  );

  screenTest('title', () => const TitleScreen());
  screenTest('stable', () => const StableScreen());
  screenTest('settings', () => const SettingsScreen());
  screenTest('about', () => const AboutScreen());
  screenTest('flock', () => const FlockScreen());
  screenTest('hatchery', () => const HatcheryScreen());
  screenTest('upgrades', () => const UpgradesScreen());
  screenTest('codex', () => const CodexScreen());

  screenTest('season entry', () => const SeasonScreen());
  screenTest('season map', () => const SeasonScreen(), prepare: _inSeason);

  screenTest(
    'trader',
    () => const TraderScreen(),
    prepare: (game) => _atNode(game, NodeKind.trader),
  );
  screenTest(
    'training',
    () => const TrainingScreen(),
    prepare: (game) => _atNode(game, NodeKind.training),
  );
  screenTest(
    'rest',
    () => const RestScreen(),
    prepare: (game) => _atNode(game, NodeKind.rest),
  );

  screenTest(
    'race',
    () => const RaceScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
    },
  );

  screenTest(
    'result',
    () => const ResultScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
      // Run the race out so the screen has a finishing order to show.
      for (var turn = 0; turn < 400; turn++) {
        if (game.engine!.phase == RacePhase.finished) break;
        game.endTurn();
      }
    },
  );

  // ------------------------------------------------------------- walkthrough

  screenTest('intro', () => const IntroScreen());

  screenTest(
    'coached stable',
    () => const StableScreen(),
    prepare: (game) => _teach(game, Lesson.stable),
  );
  screenTest(
    'coached hatchery',
    () => const HatcheryScreen(),
    prepare: (game) => _teach(game, Lesson.hatchery),
  );
  screenTest(
    'coached schedule',
    () => const SeasonScreen(),
    prepare: (game) {
      _inSeason(game);
      _teach(game, Lesson.schedule);
    },
  );
  screenTest(
    'coached race',
    () => const RaceScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
      _teach(game, Lesson.race);
    },
  );
}
