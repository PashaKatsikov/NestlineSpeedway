import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../genetics/hatchery.dart';
import '../../meta/stable.dart';
import '../../state/game.dart';
import '../../tutorial/lesson.dart';
import '../widgets/coach_mark.dart';
import '../widgets/ui_kit.dart';
import 'codex_screen.dart';
import 'flock_screen.dart';
import 'hatchery_screen.dart';
import 'season_screen.dart';
import 'settings_screen.dart';
import 'upgrades_screen.dart';

/// The hub. Everything persistent lives one tap from here.
class StableScreen extends StatefulWidget {
  const StableScreen({super.key});

  @override
  State<StableScreen> createState() => _StableScreenState();
}

class _StableScreenState extends State<StableScreen> {
  final GlobalKey _seasonKey = GlobalKey();
  final GlobalKey _eggsKey = GlobalKey();
  final GlobalKey _roomsKey = GlobalKey();

  /// Read once: the walkthrough must not restart when the screen rebuilds.
  late final bool _teaching = context.read<Game>().needsLesson(Lesson.stable);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final stable = game.stable;

    _showNotice(context, game);

    return CoachOverlay(
      active: _teaching,
      onDone: () => game.completeLesson(Lesson.stable),
      steps: [
        CoachStep(
          anchor: _seasonKey,
          icon: Icons.flag_rounded,
          title: 'A season starts here',
          body:
              'Twelve events with a Grand Prix at the end. Everything you win '
              'on the way is banked back into the stable when it closes — the '
              'birds you take are the only thing you can lose.',
        ),
        CoachStep(
          anchor: _eggsKey,
          icon: Icons.egg_alt_rounded,
          title: 'Eggs are the currency',
          body:
              'Podiums pay eggs, and eggs are what you breed and build with. '
              'Better shells sit further right and rescue more recessives.',
        ),
        CoachStep(
          anchor: _roomsKey,
          icon: Icons.grid_view_rounded,
          title: 'Four rooms',
          body:
              'Flock inspects your birds, Hatchery pairs them, Yard spends eggs '
              'on permanent upgrades, and the Codex records every allele, rival '
              'and piece of tack you have met.',
        ),
      ],
      child: _buildScreen(context, game, stable),
    );
  }

  Widget _buildScreen(BuildContext context, Game game, Stable stable) {
    return GameScreen(
      title: stable.name,
      subtitle:
          'Grade ${stable.grade} · '
          '${stable.active.length} birds in work · '
          'codex ${stable.codex.completion}%',
      plate: Plates.scene(1),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatChip(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Sprites.egg(
            stable.bestEggTier < 0 ? 0 : stable.bestEggTier,
          ),
          compact: true,
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          icon: Icons.tune_rounded,
          onTap: () =>
              Navigator.of(context).push(gameRoute(const SettingsScreen())),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _SeasonPanel(key: _seasonKey, game: game),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _EggBank(key: _eggsKey, game: game),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView(
                    key: _roomsKey,
                    // Fixed tile height, and one column when the panel is too
                    // narrow for two: the hub has to stay reachable on a phone.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisExtent: 68,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    children: [
                      _HubTile(
                        title: 'Flock',
                        blurb: '${game.stable.racers.length} birds',
                        sprite: Sprites.bird(Sprites.poseReady),
                        onTap: () => Navigator.of(
                          context,
                        ).push(gameRoute(const FlockScreen())),
                      ),
                      _HubTile(
                        title: 'Hatchery',
                        blurb: '${game.stable.hatchSlots} hatch slots',
                        sprite: Sprites.egg(3),
                        onTap: () => Navigator.of(
                          context,
                        ).push(gameRoute(const HatcheryScreen())),
                      ),
                      _HubTile(
                        title: 'Yard',
                        blurb: '${game.stable.built.length} built',
                        sprite: Sprites.stable(0),
                        onTap: () => Navigator.of(
                          context,
                        ).push(gameRoute(const UpgradesScreen())),
                      ),
                      _HubTile(
                        title: 'Codex',
                        blurb: '${game.stable.codex.completion}% recorded',
                        sprite: Sprites.plume(2),
                        onTap: () => Navigator.of(
                          context,
                        ).push(gameRoute(const CodexScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotice(BuildContext context, Game game) {
    final notice = game.notice;
    if (notice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      game.clearNotice();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice, style: Type.text(12, color: Palette.ink)),
          backgroundColor: Palette.asphaltHi,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}

class _SeasonPanel extends StatelessWidget {
  const _SeasonPanel({super.key, required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final season = game.season;
    final active = game.stable.active;

    return Panel(
      accent: Palette.amber,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            season == null ? 'The circuit' : 'Season in progress',
            subtitle: season == null
                ? 'Twelve events, one Grand Prix, one champion in the way.'
                : 'Event ${season.row} of ${season.map.rows}'
                      ' · ${season.grain} grain',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: season == null
                ? _SeasonPitch(game: game)
                : _SeasonSummary(game: game),
          ),
          const SizedBox(height: 10),
          if (season == null)
            PrimaryButton(
              label: 'Start a season',
              icon: Icons.flag_rounded,
              expand: true,
              onTap: active.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).push(gameRoute(const SeasonScreen())),
            )
          else
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onTap: () =>
                  Navigator.of(context).push(gameRoute(const SeasonScreen())),
            ),
        ],
      ),
    );
  }
}

class _SeasonPitch extends StatelessWidget {
  const _SeasonPitch({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final stable = game.stable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The blurbs wrap to three lines in a narrow panel, which is taller than
        // a phone in landscape has to spare, so the pitch scrolls.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(
                  'Grade ${stable.grade}',
                  'Rivals scale with your best birds; grade is the difficulty '
                      'on top.',
                ),
                _Fact(
                  '${stable.rosterSlots} travelling slots',
                  'Take a first-choice racer and reserves in case of injury.',
                ),
                _Fact(
                  '${stable.startingGrain} starting grain',
                  'Spent at Traders on tack, feed and gene reads.',
                ),
              ],
            ),
          ),
        ),
        if (stable.seasonsRun > 0)
          Text(
            '${stable.seasonsRun} seasons run · ${stable.seasonsWon} won · '
            '${stable.totalWins} race wins',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Type.text(11),
          ),
      ],
    );
  }
}

class _SeasonSummary extends StatelessWidget {
  const _SeasonSummary({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final racer = game.activeRacer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (racer != null)
                  _Fact(
                    racer.name,
                    'Entered next. ${racer.fatigue} fatigue, '
                    '${racer.injuries.length} injuries.',
                  ),
                _Fact(
                  '${season.racesWon} wins from ${season.racesRun} starts',
                  'Placements pay grain now and eggs when the season closes.',
                ),
                _Fact(
                  '${season.tackOwned.length} pieces of tack',
                  'Won or bought this season. Fitted gear is lost when it ends.',
                ),
              ],
            ),
          ),
        ),
        GhostButton(
          label: 'Retire from the season',
          icon: Icons.logout_rounded,
          tint: Palette.bad,
          compact: true,
          onTap: () => _confirmRetire(context),
        ),
      ],
    );
  }

  void _confirmRetire(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.asphalt,
        title: Text('Retire from the season?', style: Type.title(17)),
        content: Text(
          'Eggs you have already won are banked. Tack and supplies are lost.',
          style: Type.text(12),
        ),
        actions: [
          GhostButton(
            label: 'Keep racing',
            compact: true,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          PrimaryButton(
            label: 'Retire',
            compact: true,
            onTap: () {
              context.read<Game>().retireSeasonEarly();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.title, this.blurb);
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Type.title(14, color: Palette.amber)),
          Text(blurb, style: Type.text(11)),
        ],
      ),
    );
  }
}

class _EggBank extends StatelessWidget {
  const _EggBank({super.key, required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final eggs = game.stable.eggs;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Egg bank',
            subtitle: 'The only currency that breeds and builds.',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                for (var tier = 0; tier < eggs.length; tier++)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${EggTier.at(tier).name}\n'
                          '${EggTier.at(tier).blurb}',
                      child: Opacity(
                        opacity: eggs[tier] > 0 ? 1 : 0.32,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Image.asset(
                                Sprites.egg(tier),
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${eggs[tier]}',
                              style: Type.number(
                                13,
                                color: Palette.tiers[tier],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.blurb,
    required this.sprite,
    required this.onTap,
  });

  final String title;
  final String blurb;
  final String sprite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Image.asset(sprite, width: 42, height: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Type.title(15),
                ),
                const SizedBox(height: 2),
                Text(
                  blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Type.text(10.5),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Palette.inkMute,
          ),
        ],
      ),
    );
  }
}
