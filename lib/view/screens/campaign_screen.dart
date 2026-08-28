import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/runner.dart';
import 'package:nestline_circuit/campaign/kit.dart';
import 'package:nestline_circuit/campaign/nodes.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/walkthrough/guide.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/guide_overlay.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';
import 'package:nestline_circuit/view/screens/heat_screen.dart';
import 'package:nestline_circuit/view/screens/recover_screen.dart';
import 'package:nestline_circuit/view/screens/merchant_screen.dart';
import 'package:nestline_circuit/view/screens/drill_screen.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    if (!game.seasonActive) return const _GateView();
    return const _BookWalk();
  }
}

// ---------------------------------------------------------------------- entry

class _GateView extends StatefulWidget {
  const _GateView();

  @override
  State<_GateView> createState() => _GateViewState();
}

class _GateViewState extends State<_GateView> {
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final available = game.stable.active;
    final slots = game.stable.rosterSlots;

    return Stage(
      title: 'Season entry',
      subtitle:
          'Pick up to $slots birds. The first one starts the opening '
          'sprint; the rest are cover for injuries.',
      plate: Backdrops.scene(4),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: available.isEmpty
                ? const VacantNote('No birds fit to race. Breed or claim first.')
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
                      return RunnerCard(
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
                                  gradient: Washes.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: Face.number(
                                    12,
                                    color: Pigment.inkOnLight,
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
            child: Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Entry list'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _picked.isEmpty
                        ? Text(
                            'Tap birds to add them. Order matters only for who '
                            'lines up first — you can switch between events.',
                            style: Face.text(11.5),
                          )
                        : ListView(
                            children: [
                              for (var i = 0; i < _picked.length; i++)
                                _GateLine(
                                  index: i,
                                  racer: game.stable.byId(_picked[i])!,
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  LeadButton(
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

class _GateLine extends StatelessWidget {
  const _GateLine({required this.index, required this.racer});
  final int index;
  final Runner racer;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('${index + 1}', style: Face.number(13, color: Pigment.amber)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(racer.name, style: Face.title(13)),
                Text(
                  '${pheno.maneuverIds.length} commands · '
                  '${pheno.rating} rating',
                  style: Face.text(10),
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

class _BookWalk extends StatefulWidget {
  const _BookWalk();

  @override
  State<_BookWalk> createState() => _BookWalkState();
}

class _BookWalkState extends State<_BookWalk> {
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _lineKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  late final bool _teaching = context.read<Director>().needsGuide(Guide.schedule);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();

    return GuideOverlay(
      active: _teaching,
      onDone: () => game.completeGuide(Guide.schedule),
      steps: [
        GuideBeat(
          anchor: _mapKey,
          icon: Icons.alt_route_rounded,
          title: 'You choose the route',
          body:
              'Each column offers a choice and you only get one of them. A '
              'Trader you walk past is tack you never own; a Rest you skip is '
              'fatigue you carry into the Grand Prix.',
        ),
        GuideBeat(
          anchor: _lineKey,
          icon: Icons.pets_rounded,
          title: 'Who lines up',
          body:
              'Stamina is what this bird starts a race with and fatigue is what '
              'it has left over from the last one. Swap in a reserve, fit tack, '
              'or spend something from the bag before you travel.',
        ),
        GuideBeat(
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

  Widget _buildScreen(BuildContext context, Director game) {
    final season = game.season!;
    final pending = season.pendingNodeId == null
        ? null
        : season.map.byId(season.pendingNodeId!);

    return Stage(
      title: 'Season schedule',
      subtitle:
          'Grade ${season.grade} · event ${season.row} of '
          '${season.map.rows}',
      plate: Backdrops.scene(6),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatMark(
          label: 'grain',
          value: '${season.grain}',
          iconAsset: Atlas.grain,
          compact: true,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Pane(
              key: _mapKey,
              padding: const EdgeInsets.all(10),
              child: _BookView(game: game),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 268,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StopPanel(key: _lineKey, game: game),
                ),
                const SizedBox(height: 10),
                if (pending != null)
                  _QueuedAct(key: _nextKey, node: pending)
                else
                  Pane(
                    key: _nextKey,
                    padding: const EdgeInsets.all(11),
                    child: Text(
                      'Pick your next event on the schedule. A Trader you skip '
                      'is tack you never get.',
                      style: Face.text(11.5),
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

class _BookView extends StatelessWidget {
  const _BookView({required this.game});
  final Director game;

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
                    child: _StopChip(
                      node: node,
                      state: season.cleared.contains(node.id)
                          ? _StopPaint.done
                          : available.contains(node.id)
                          ? _StopPaint.open
                          : _StopPaint.locked,
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
                child: Icon(Icons.more_horiz, size: 16, color: Pigment.inkMute),
              ),
          ],
        ],
      ),
    );
  }
}

enum _StopPaint { done, open, locked }

class _StopChip extends StatelessWidget {
  const _StopChip({required this.node, required this.state, this.onTap});

  final CircuitStop node;
  final _StopPaint state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = node.kind.tint;
    final open = state == _StopPaint.open;
    final done = state == _StopPaint.done;

    return Tooltip(
      message:
          '${node.kind.label} — ${node.venue.name}\n'
          '${node.kind.blurb}',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: done
                ? Pigment.slate.withValues(alpha: 0.55)
                : Pigment.asphaltHi,
            borderRadius: BorderRadius.circular(Corners.rSm),
            border: Border.all(
              color: open
                  ? tint
                  : done
                  ? Pigment.slateHi
                  : Pigment.slate,
              width: open ? 2 : 1,
            ),
            boxShadow: open ? Corners.glow(tint, 0.4) : null,
          ),
          child: Column(
            children: [
              Icon(
                done ? Icons.check_rounded : node.kind.icon,
                size: 18,
                color: open ? tint : Pigment.inkMute,
              ),
              const SizedBox(height: 3),
              Text(
                node.kind.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Face.text(
                  9.5,
                  color: open ? Pigment.ink : Pigment.inkMute,
                ),
              ),
              Text(
                node.venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Face.text(8, color: Pigment.inkMute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopPanel extends StatelessWidget {
  const _StopPanel({super.key, required this.game});
  final Director game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final racer = game.activeRacer;
    final pheno = game.activePhenotype;

    return Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneTitle('At the line'),
          const SizedBox(height: 8),
          if (racer == null || pheno == null)
            const Expanded(child: VacantNote('No fit bird in the string.'))
          else
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      HenView(
                        pose: racer.portraitPose,
                        plume: racer.plume,
                        size: 52,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(racer.name, style: Face.title(15)),
                            Text(
                              '${pheno.stride} stride · ${pheno.effort} effort '
                              '· ${pheno.grip} grip',
                              style: Face.text(10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GaugeBar(
                    value: pheno.staminaMax,
                    max: pheno.staminaMax,
                    tint: Pigment.stamina,
                    label: 'Stamina at the flag',
                  ),
                  const SizedBox(height: 7),
                  GaugeBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Pigment.bad : Pigment.warn,
                    label: 'Fatigue',
                  ),
                  const SizedBox(height: 10),
                  if (season.rosterIds.length > 1) ...[
                    Text('SWITCH RACER', style: Face.label(8.5)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final other in game.roster)
                          QuietButton(
                            label: other.name,
                            compact: true,
                            tint: other.id == racer.id
                                ? Pigment.amber
                                : other.careerOver
                                ? Pigment.bad
                                : Pigment.inkSoft,
                            onTap: other.careerOver || other.id == racer.id
                                ? null
                                : () => game.setActiveRacer(other.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  _GearRow(game: game, racer: racer),
                  const SizedBox(height: 10),
                  _SatchelRow(game: game),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GearRow extends StatelessWidget {
  const _GearRow({required this.game, required this.racer});
  final Director game;
  final Runner racer;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    if (season.tackOwned.isEmpty) {
      return Text(
        'No tack yet. Traders and duels supply it.',
        style: Face.text(10.5),
      );
    }
    final equipped = season.equippedOn(racer.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TACK ${equipped.length}/${game.stable.tackSlots}',
          style: Face.label(8.5),
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
                  child: Pressable(
                    onTap: () => game.toggleTack(racer.id, id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: equipped.contains(id)
                            ? Pigment.amber.withValues(alpha: 0.2)
                            : Pigment.pitch.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: equipped.contains(id)
                              ? Pigment.amber
                              : Pigment.slate,
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

class _SatchelRow extends StatelessWidget {
  const _SatchelRow({required this.game});
  final Director game;

  @override
  Widget build(BuildContext context) {
    final season = game.season!;
    final contents = season.bagContents;
    if (contents.isEmpty) {
      return Text('The bag is empty.', style: Face.text(10.5));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUPPLIES', style: Face.label(8.5)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in contents)
              Tooltip(
                message: '${item.name}\n${item.blurb}',
                child: Pressable(
                  onTap: () => game.useConsumable(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Pigment.pitch.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Pigment.slate),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(item.iconPath, width: 24, height: 24),
                        const SizedBox(width: 3),
                        Text(
                          '${season.countOf(item.id)}',
                          style: Face.number(11),
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
              style: Face.text(10, color: Pigment.stamina),
            ),
          ),
      ],
    );
  }
}

class _QueuedAct extends StatelessWidget {
  const _QueuedAct({super.key, required this.node});
  final CircuitStop node;

  @override
  Widget build(BuildContext context) {
    final game = context.read<Director>();
    return Pane(
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
                  style: Face.title(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(node.venue.blurb, style: Face.text(11)),
          const SizedBox(height: 10),
          LeadButton(
            label: switch (node.kind) {
              StopKind.trader => 'Visit the trader',
              StopKind.training => 'Spend the day',
              StopKind.rest => 'Rest up',
              _ => 'Go to the line',
            },
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onTap: () {
              switch (node.kind) {
                case StopKind.trader:
                  Navigator.of(context).push(stageRoute(const MerchantScreen()));
                case StopKind.training:
                  Navigator.of(context).push(stageRoute(const DrillScreen()));
                case StopKind.rest:
                  Navigator.of(context).push(stageRoute(const RecoverScreen()));
                default:
                  game.startRace(node);
                  Navigator.of(context).push(stageRoute(const HeatScreen()));
              }
            },
          ),
        ],
      ),
    );
  }
}
