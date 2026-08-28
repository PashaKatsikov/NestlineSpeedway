import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support.dart';

import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/heat/engine.dart';
import 'package:nestline_circuit/campaign/nodes.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/screens/primer_screen.dart';
import 'package:nestline_circuit/view/screens/ledger_screen.dart';
import 'package:nestline_circuit/view/screens/runners_screen.dart';
import 'package:nestline_circuit/walkthrough/guide.dart';
import 'package:nestline_circuit/view/screens/brooder_screen.dart';
import 'package:nestline_circuit/view/screens/opening_screen.dart';
import 'package:nestline_circuit/view/screens/boot_screen.dart';
import 'package:nestline_circuit/view/screens/heat_screen.dart';
import 'package:nestline_circuit/view/screens/recover_screen.dart';
import 'package:nestline_circuit/view/screens/payout_screen.dart';
import 'package:nestline_circuit/view/screens/campaign_screen.dart';
import 'package:nestline_circuit/view/screens/options_screen.dart';
import 'package:nestline_circuit/view/screens/yard_screen.dart';
import 'package:nestline_circuit/view/screens/menu_screen.dart';
import 'package:nestline_circuit/view/screens/merchant_screen.dart';
import 'package:nestline_circuit/view/screens/drill_screen.dart';
import 'package:nestline_circuit/view/screens/works_screen.dart';

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

Future<Director> _bootedGame() async {
  freshSave();
  final game = Director();
  await game.boot();
  // Screens are tested bare by default. The walkthrough draws over the top of
  // them, so it gets its own set of cases rather than colouring every one.
  game.stable.introSeen = true;
  for (final lesson in Guide.values) {
    game.completeGuide(lesson);
  }
  return game;
}

/// Re-arms one walkthrough so the screen builds with its coach marks showing.
void _teach(Director game, Guide lesson) =>
    game.stable.guidesSeen.remove(lesson.name);

Future<void> _show(WidgetTester tester, Director game, Widget screen) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<Director>.value(
      value: game,
      child: MaterialApp(theme: Look.dark, home: screen),
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
  void Function(Director game)? prepare,
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
void _inSeason(Director game) {
  game.startSeason(game.stable.racers.map((r) => r.id).toList());
}

/// Walks the schedule until it reaches a node of [kind] so the encounter screens
/// have real content to render.
///
/// Row 0 is always the opening sprint and the map is randomised, so this steps
/// forward node by node and starts a fresh season if a route runs out.
void _atNode(Director game, StopKind kind) {
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
  screenTest('loading', () => const BootScreen());
  screenTest(
    'loading upright',
    () => const BootScreen(),
    viewports: _portraitViewports,
  );

  screenTest('title', () => const MenuScreen());
  screenTest('stable', () => const YardScreen());
  screenTest('settings', () => const OptionsScreen());
  screenTest('about', () => const PrimerScreen());
  screenTest('flock', () => const RunnersScreen());
  screenTest('hatchery', () => const BrooderScreen());
  screenTest('upgrades', () => const WorksScreen());
  screenTest('codex', () => const LedgerScreen());

  screenTest('season entry', () => const CampaignScreen());
  screenTest('season map', () => const CampaignScreen(), prepare: _inSeason);

  screenTest(
    'trader',
    () => const MerchantScreen(),
    prepare: (game) => _atNode(game, StopKind.trader),
  );
  screenTest(
    'training',
    () => const DrillScreen(),
    prepare: (game) => _atNode(game, StopKind.training),
  );
  screenTest(
    'rest',
    () => const RecoverScreen(),
    prepare: (game) => _atNode(game, StopKind.rest),
  );

  screenTest(
    'race',
    () => const HeatScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
    },
  );

  screenTest(
    'result',
    () => const PayoutScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
      // Run the race out so the screen has a finishing order to show.
      for (var turn = 0; turn < 400; turn++) {
        if (game.engine!.phase == HeatPhase.finished) break;
        game.endTurn();
      }
    },
  );

  // ------------------------------------------------------------- walkthrough

  screenTest('intro', () => const OpeningScreen());

  screenTest(
    'coached stable',
    () => const YardScreen(),
    prepare: (game) => _teach(game, Guide.stable),
  );
  screenTest(
    'coached hatchery',
    () => const BrooderScreen(),
    prepare: (game) => _teach(game, Guide.hatchery),
  );
  screenTest(
    'coached schedule',
    () => const CampaignScreen(),
    prepare: (game) {
      _inSeason(game);
      _teach(game, Guide.schedule);
    },
  );
  screenTest(
    'coached race',
    () => const HeatScreen(),
    prepare: (game) {
      _inSeason(game);
      final node = game.season!.available.first;
      game.travelTo(node);
      game.startRace(node);
      _teach(game, Guide.race);
    },
  );
}
