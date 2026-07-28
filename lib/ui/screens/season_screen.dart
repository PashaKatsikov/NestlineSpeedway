import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../genetics/racer.dart';
import '../../season/items.dart';
import '../../season/season_map.dart';
import '../../state/game.dart';
import '../../tutorial/lesson.dart';
import '../widgets/bird_view.dart';
import '../widgets/coach_mark.dart';
import '../widgets/ui_kit.dart';
import 'race_screen.dart';
import 'rest_screen.dart';
import 'trader_screen.dart';
import 'training_screen.dart';

class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    if (!game.seasonActive) return const _EntryView();
    return const _ScheduleView();
  }
}

// ---------------------------------------------------------------------- entry

class _EntryView extends StatefulWidget {
  const _EntryView();

  @override
  State<_EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<_EntryView> {
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final available = game.stable.active;
    final slots = game.stable.rosterSlots;

    return GameScreen(
      title: 'Season entry',
      subtitle:
          'Pick up to $slots birds. The first one starts the opening '
          'sprint; the rest are cover for injuries.',
      plate: Plates.scene(4),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: available.isEmpty
                ? const EmptyNote('No birds fit to race. Breed or claim first.')
                : GridView.builder(
                    // A fixed row height rather than an aspect ratio: the card
                    // needs a predictable amount of vertical room, and the grid
                    // is much narrower on a phone than on a tablet.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 96,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                        ),
                    itemCount: available.length,
                    itemBuilder: (context, i) {
                      final racer = available[i];
                      final index = _picked.indexOf(racer.id);
                      return RacerCard(
                        racer: racer,
                        selected: index >= 0,
                        compact: true,
                        trailing: index < 0
                            ? null
                            : Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  gradient: Grads.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: Type.number(
                                    12,
                                    color: Palette.inkOnLight,
                                  ),
                                ),
                              ),
                        onTap: () => setState(() {
                          if (index >= 0) {
                            _picked.remove(racer.id);
                          } else if (_picked.length < slots) {
                            _picked.add(racer.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 250,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Entry list'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _picked.isEmpty
                        ? Text(
                            'Tap birds to add them. Order matters only for who '
                            'lines up first — you can switch between events.',
                            style: Type.text(11.5),
                          )
                        : ListView(
                            children: [
                              for (var i = 0; i < _picked.length; i++)
                                _EntryLine(
                                  index: i,
                                  racer: game.stable.byId(_picked[i])!,
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Line up',
                    icon: Icons.sports_score_rounded,
                    expand: true,
                    onTap: _picked.isEmpty
                        ? null
                        : () => game.startSeason(_picked),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.index, required this.racer});
  final int index;
  final Racer racer;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('${index + 1}', style: Type.number(13, color: Palette.amber)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(racer.name, style: Type.title(13)),
                Text(
                  '${pheno.commandIds.length} commands · '
                  '${pheno.rating} rating',
                  style: Type.text(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- schedule

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _lineKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  late final bool _teaching = context.read<Game>().needsLesson(Lesson.schedule);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();

    return CoachOverlay(
      active: _teaching,
      onDone: () => game.completeLesson(Lesson.schedule),
      steps: [
        CoachStep(
          anchor: _mapKey,
          icon: Icons.alt_route_rounded,
          title: 'You choose the route',
          body:
              'Each column offers a choice and you only get one of them. A '
              'Trader you walk past is tack you never own; a Rest you skip is '
              'fatigue you carry into the Grand Prix.',
        ),
        CoachStep(
          anchor: _lineKey,
          icon: Icons.pets_rounded,
          title: 'Who lines up',
          body:
              'Stamina is what this bird starts a race with and fatigue is what '
              'it has left over from the last one. Swap in a reserve, fit tack, '
              'or spend something from the bag before you travel.',
        ),
        CoachStep(
          anchor: _nextKey,
          icon: Icons.arrow_forward_rounded,
          title: 'Then commit',
          body:
              'Picking an event on the schedule brings you here. Nothing is '
              'spent until you go to the line, so set the bird up first.',
        ),
      ],
      child: _buildScreen(context, game),
    );
  }

  Widget _buildScreen(BuildContext context, Game game) {
    final season = game.season!;
    final pending = season.pendingNodeId == null
        ? null
        : season.map.byId(season.pendingNodeId!);

    return GameScreen(
      title: 'Season schedule',
      subtitle:
          'Grade ${season.grade} · event ${season.row} of '
          '${season.map.rows}',
      plate: Plates.scene(6),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatChip(
          label: 'grain',
          value: '${season.grain}',
          iconAsset: Sprites.grain,
          compact: true,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Panel(
              key: _mapKey,
              padding: const EdgeInsets.all(10),
              child: _MapView(game: game),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 268,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ActivePanel(key: _lineKey, game: game),
                ),
                const SizedBox(height: 10),
                if (pending != null)
                  _PendingAction(key: _nextKey, node: pending)
                else
                  Panel(
                    key: _nextKey,
                    padding: const EdgeInsets.all(11),
                    child: Text(
                      'Pick your next event on the schedule. A Trader you skip '
                      'is tack you never get.',
                      style: Type.text(11.5),
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

class _MapView extends StatelessWidget {
  const _MapView({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final available = season.available.map((n) => n.id).toSet();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var row = 0; row < season.map.rows; row++) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final node in season.map.inRow(row))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: _NodeChip(
                      node: node,
                      state: season.cleared.contains(node.id)
                          ? _NodeState.done
                          : available.contains(node.id)
                          ? _NodeState.open
                          : _NodeState.locked,
                      onTap:
                          available.contains(node.id) &&
                              season.pendingNodeId == null
                          ? () => game.travelTo(node)
                          : null,
                    ),
                  ),
              ],
            ),
            if (row < season.map.rows - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.more_horiz, size: 16, color: Palette.inkMute),
              ),
          ],
        ],
      ),
    );
  }
}

enum _NodeState { done, open, locked }

class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.node, required this.state, this.onTap});

  final SeasonNode node;
  final _NodeState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = node.kind.tint;
    final open = state == _NodeState.open;
    final done = state == _NodeState.done;

    return Tooltip(
      message:
          '${node.kind.label} — ${node.venue.name}\n'
          '${node.kind.blurb}',
      child: Tappable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: done
                ? Palette.slate.withValues(alpha: 0.55)
                : Palette.asphaltHi,
            borderRadius: BorderRadius.circular(Shape.rSm),
            border: Border.all(
              color: open
                  ? tint
                  : done
                  ? Palette.slateHi
                  : Palette.slate,
              width: open ? 2 : 1,
            ),
            boxShadow: open ? Shape.glow(tint, 0.4) : null,
          ),
          child: Column(
            children: [
              Icon(
                done ? Icons.check_rounded : node.kind.icon,
                size: 18,
                color: open ? tint : Palette.inkMute,
              ),
              const SizedBox(height: 3),
              Text(
                node.kind.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.text(
                  9.5,
                  color: open ? Palette.ink : Palette.inkMute,
                ),
              ),
              Text(
                node.venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.text(8, color: Palette.inkMute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({super.key, required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final racer = game.activeRacer;
    final pheno = game.activePhenotype;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('At the line'),
          const SizedBox(height: 8),
          if (racer == null || pheno == null)
            const Expanded(child: EmptyNote('No fit bird in the string.'))
          else
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      BirdView(
                        pose: racer.portraitPose,
                        plume: racer.plume,
                        size: 52,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(racer.name, style: Type.title(15)),
                            Text(
                              '${pheno.stride} stride · ${pheno.effort} effort '
                              '· ${pheno.grip} grip',
                              style: Type.text(10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MeterBar(
                    value: pheno.staminaMax,
                    max: pheno.staminaMax,
                    tint: Palette.stamina,
                    label: 'Stamina at the flag',
                  ),
                  const SizedBox(height: 7),
                  MeterBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Palette.bad : Palette.warn,
                    label: 'Fatigue',
                  ),
                  const SizedBox(height: 10),
                  if (season.rosterIds.length > 1) ...[
                    Text('SWITCH RACER', style: Type.label(8.5)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final other in game.roster)
                          GhostButton(
                            label: other.name,
                            compact: true,
                            tint: other.id == racer.id
                                ? Palette.amber
                                : other.careerOver
                                ? Palette.bad
                                : Palette.inkSoft,
                            onTap: other.careerOver || other.id == racer.id
                                ? null
                                : () => game.setActiveRacer(other.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  _TackRow(game: game, racer: racer),
                  const SizedBox(height: 10),
                  _BagRow(game: game),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TackRow extends StatelessWidget {
  const _TackRow({required this.game, required this.racer});
  final Game game;
  final Racer racer;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    if (season.tackOwned.isEmpty) {
      return Text(
        'No tack yet. Traders and duels supply it.',
        style: Type.text(10.5),
      );
    }
    final equipped = season.equippedOn(racer.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TACK ${equipped.length}/${game.stable.tackSlots}',
          style: Type.label(8.5),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final id in season.tackOwned)
              if (Tack.byId(id) != null)
                Tooltip(
                  message:
                      '${Tack.byId(id)!.name}\n'
                      '${Tack.byId(id)!.blurb}\n'
                      '${Tack.byId(id)!.mods.describe()}',
                  child: Tappable(
                    onTap: () => game.toggleTack(racer.id, id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: equipped.contains(id)
                            ? Palette.amber.withValues(alpha: 0.2)
                            : Palette.pitch.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: equipped.contains(id)
                              ? Palette.amber
                              : Palette.slate,
                        ),
                      ),
                      child: Image.asset(
                        Tack.byId(id)!.iconPath,
                        width: 26,
                        height: 26,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _BagRow extends StatelessWidget {
  const _BagRow({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final contents = season.bagContents;
    if (contents.isEmpty) {
      return Text('The bag is empty.', style: Type.text(10.5));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUPPLIES', style: Type.label(8.5)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in contents)
              Tooltip(
                message: '${item.name}\n${item.blurb}',
                child: Tappable(
                  onTap: () => game.useConsumable(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Palette.pitch.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Palette.slate),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(item.iconPath, width: 24, height: 24),
                        const SizedBox(width: 3),
                        Text(
                          '${season.countOf(item.id)}',
                          style: Type.number(11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (season.primed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Primed for the next race: '
              '${season.primed.map((id) => Consumable.byId(id)?.name ?? id).join(', ')}',
              style: Type.text(10, color: Palette.stamina),
            ),
          ),
      ],
    );
  }
}

class _PendingAction extends StatelessWidget {
  const _PendingAction({super.key, required this.node});
  final SeasonNode node;

  @override
  Widget build(BuildContext context) {
    final game = context.read<Game>();
    return Panel(
      accent: node.kind.tint,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(node.kind.icon, size: 18, color: node.kind.tint),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${node.kind.label} · ${node.venue.name}',
                  style: Type.title(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(node.venue.blurb, style: Type.text(11)),
          const SizedBox(height: 10),
          PrimaryButton(
            label: switch (node.kind) {
              NodeKind.trader => 'Visit the trader',
              NodeKind.training => 'Spend the day',
              NodeKind.rest => 'Rest up',
              _ => 'Go to the line',
            },
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onTap: () {
              switch (node.kind) {
                case NodeKind.trader:
                  Navigator.of(context).push(gameRoute(const TraderScreen()));
                case NodeKind.training:
                  Navigator.of(context).push(gameRoute(const TrainingScreen()));
                case NodeKind.rest:
                  Navigator.of(context).push(gameRoute(const RestScreen()));
                default:
                  game.startRace(node);
                  Navigator.of(context).push(gameRoute(const RaceScreen()));
              }
            },
          ),
        ],
      ),
    );
  }
}
