import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/brooder.dart';
import 'package:nestline_circuit/yard/roster.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/walkthrough/guide.dart';
import 'package:nestline_circuit/view/widgets/guide_overlay.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';
import 'package:nestline_circuit/view/screens/ledger_screen.dart';
import 'package:nestline_circuit/view/screens/runners_screen.dart';
import 'package:nestline_circuit/view/screens/brooder_screen.dart';
import 'package:nestline_circuit/view/screens/campaign_screen.dart';
import 'package:nestline_circuit/view/screens/options_screen.dart';
import 'package:nestline_circuit/view/screens/works_screen.dart';

/// The hub. Everything persistent lives one tap from here.
class YardScreen extends StatefulWidget {
  const YardScreen({super.key});

  @override
  State<YardScreen> createState() => _YardScreenState();
}

class _YardScreenState extends State<YardScreen> {
  final GlobalKey _seasonKey = GlobalKey();
  final GlobalKey _eggsKey = GlobalKey();
  final GlobalKey _roomsKey = GlobalKey();

  /// Read once: the walkthrough must not restart when the screen rebuilds.
  late final bool _teaching = context.read<Director>().needsGuide(Guide.stable);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final stable = game.stable;

    _showNotice(context, game);

    return GuideOverlay(
      active: _teaching,
      onDone: () => game.completeGuide(Guide.stable),
      steps: [
        GuideBeat(
          anchor: _seasonKey,
          icon: Icons.flag_rounded,
          title: 'A season starts here',
          body:
              'Twelve events with a Grand Prix at the end. Everything you win '
              'on the way is banked back into the stable when it closes — the '
              'birds you take are the only thing you can lose.',
        ),
        GuideBeat(
          anchor: _eggsKey,
          icon: Icons.egg_alt_rounded,
          title: 'Eggs are the currency',
          body:
              'Podiums pay eggs, and eggs are what you breed and build with. '
              'Better shells sit further right and rescue more recessives.',
        ),
        GuideBeat(
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

  Widget _buildScreen(BuildContext context, Director game, Yard stable) {
    return Stage(
      title: stable.name,
      subtitle:
          'Grade ${stable.grade} · '
          '${stable.active.length} birds in work · '
          'codex ${stable.codex.completion}%',
      plate: Backdrops.scene(1),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatMark(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Atlas.egg(
            stable.bestEggTier < 0 ? 0 : stable.bestEggTier,
          ),
          compact: true,
        ),
        const SizedBox(width: 8),
        OrbButton(
          icon: Icons.tune_rounded,
          onTap: () =>
              Navigator.of(context).push(stageRoute(const OptionsScreen())),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _CampaignPanel(key: _seasonKey, game: game),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ShellBank(key: _eggsKey, game: game),
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
                      _YardTile(
                        title: 'Flock',
                        blurb: '${game.stable.racers.length} birds',
                        sprite: Atlas.bird(Atlas.poseReady),
                        onTap: () => Navigator.of(
                          context,
                        ).push(stageRoute(const RunnersScreen())),
                      ),
                      _YardTile(
                        title: 'Hatchery',
                        blurb: '${game.stable.hatchSlots} hatch slots',
                        sprite: Atlas.egg(3),
                        onTap: () => Navigator.of(
                          context,
                        ).push(stageRoute(const BrooderScreen())),
                      ),
                      _YardTile(
                        title: 'Yard',
                        blurb: '${game.stable.built.length} built',
                        sprite: Atlas.stable(0),
                        onTap: () => Navigator.of(
                          context,
                        ).push(stageRoute(const WorksScreen())),
                      ),
                      _YardTile(
                        title: 'Codex',
                        blurb: '${game.stable.codex.completion}% recorded',
                        sprite: Atlas.plume(2),
                        onTap: () => Navigator.of(
                          context,
                        ).push(stageRoute(const LedgerScreen())),
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

  void _showNotice(BuildContext context, Director game) {
    final notice = game.notice;
    if (notice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      game.clearNotice();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice, style: Face.text(12, color: Pigment.ink)),
          backgroundColor: Pigment.asphaltHi,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}

class _CampaignPanel extends StatelessWidget {
  const _CampaignPanel({super.key, required this.game});
  final Director game;

  @override
  Widget build(BuildContext context) {
    final season = game.season;
    final active = game.stable.active;

    return Pane(
      accent: Pigment.amber,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaneTitle(
            season == null ? 'The circuit' : 'Season in progress',
            subtitle: season == null
                ? 'Twelve events, one Grand Prix, one champion in the way.'
                : 'Event ${season.row} of ${season.map.rows}'
                      ' · ${season.grain} grain',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: season == null
                ? _CampaignPitch(game: game)
                : _CampaignSummary(game: game),
          ),
          const SizedBox(height: 10),
          if (season == null)
            LeadButton(
              label: 'Start a season',
              icon: Icons.flag_rounded,
              expand: true,
              onTap: active.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).push(stageRoute(const CampaignScreen())),
            )
          else
            LeadButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onTap: () =>
                  Navigator.of(context).push(stageRoute(const CampaignScreen())),
            ),
        ],
      ),
    );
  }
}

class _CampaignPitch extends StatelessWidget {
  const _CampaignPitch({required this.game});
  final Director game;

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
            style: Face.text(11),
          ),
      ],
    );
  }
}

class _CampaignSummary extends StatelessWidget {
  const _CampaignSummary({required this.game});
  final Director game;

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
        QuietButton(
          label: 'Retire from the season',
          icon: Icons.logout_rounded,
          tint: Pigment.bad,
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
        backgroundColor: Pigment.asphalt,
        title: Text('Retire from the season?', style: Face.title(17)),
        content: Text(
          'Eggs you have already won are banked. Tack and supplies are lost.',
          style: Face.text(12),
        ),
        actions: [
          QuietButton(
            label: 'Keep racing',
            compact: true,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          LeadButton(
            label: 'Retire',
            compact: true,
            onTap: () {
              context.read<Director>().retireSeasonEarly();
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
          Text(title, style: Face.title(14, color: Pigment.amber)),
          Text(blurb, style: Face.text(11)),
        ],
      ),
    );
  }
}

class _ShellBank extends StatelessWidget {
  const _ShellBank({super.key, required this.game});
  final Director game;

  @override
  Widget build(BuildContext context) {
    final eggs = game.stable.eggs;
    return Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneTitle(
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
                          '${ShellTier.at(tier).name}\n'
                          '${ShellTier.at(tier).blurb}',
                      child: Opacity(
                        opacity: eggs[tier] > 0 ? 1 : 0.32,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Image.asset(
                                Atlas.egg(tier),
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${eggs[tier]}',
                              style: Face.number(
                                13,
                                color: Pigment.tiers[tier],
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

class _YardTile extends StatelessWidget {
  const _YardTile({
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
    return Pane(
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
                  style: Face.title(15),
                ),
                const SizedBox(height: 2),
                Text(
                  blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Face.text(10.5),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Pigment.inkMute,
          ),
        ],
      ),
    );
  }
}
