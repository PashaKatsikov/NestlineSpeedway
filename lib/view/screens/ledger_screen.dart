import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/heredity.dart';
import 'package:nestline_circuit/blood/locus.dart';
import 'package:nestline_circuit/heat/maneuver.dart';
import 'package:nestline_circuit/heat/maneuvers.dart';
import 'package:nestline_circuit/heat/rival.dart';
import 'package:nestline_circuit/heat/track.dart';
import 'package:nestline_circuit/campaign/kit.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/maneuver_card.dart';
import 'package:nestline_circuit/view/widgets/heredity_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// The record: alleles, synergies, commands, venues, rivals and tack.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  int _tab = 0;

  static const List<String> _tabs = [
    'Genetics',
    'Commands',
    'Venues',
    'Rivals',
    'Tack',
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final codex = game.stable.codex;

    return Stage(
      title: 'Codex',
      subtitle:
          '${codex.completion}% recorded · '
          '${codex.alleles.length} of ${codex.alleleTotal} alleles identified',
      plate: Backdrops.scene(7),
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                QuietButton(
                  label: _tabs[i],
                  compact: true,
                  tint: _tab == i ? Pigment.amber : Pigment.inkMute,
                  onTap: () => setState(() => _tab = i),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(game)),
        ],
      ),
    );
  }

  Widget _body(Director game) {
    final codex = game.stable.codex;
    return switch (_tab) {
      0 => _BloodTab(game: game),
      1 => _ManeuversTab(known: codex.commands),
      2 => _CourseTab(known: codex.venues),
      3 => _FieldTab(known: codex.rivals, champions: codex.champions),
      _ => _GearTab(known: codex.tack),
    };
  }
}

class _BloodTab extends StatelessWidget {
  const _BloodTab({required this.game});
  final Director game;

  @override
  Widget build(BuildContext context) {
    final codex = game.stable.codex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Pane(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                for (final l in Locus.values) ...[
                  Text(l.label.toUpperCase(), style: Face.label(9)),
                  Text(l.governs, style: Face.text(10.5)),
                  const SizedBox(height: 6),
                  for (final allele in l.alleles)
                    _AlleleLine(
                      allele: allele,
                      known: codex.knowsAllele(l, allele.index),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 268,
          child: Pane(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaneTitle(
                  'Synergies',
                  subtitle:
                      '${codex.synergies.length} of '
                      '${Pairings.all.length} found',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      for (final s in Pairings.all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                codex.synergies.contains(s.command)
                                    ? Icons.auto_awesome
                                    : Icons.lock_outline_rounded,
                                size: 13,
                                color: codex.synergies.contains(s.command)
                                    ? Pigment.schoolRainbow
                                    : Pigment.inkMute,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      codex.synergies.contains(s.command)
                                          ? s.name
                                          : 'Undiscovered',
                                      style: Face.title(
                                        12,
                                        color:
                                            codex.synergies.contains(s.command)
                                            ? Pigment.schoolRainbow
                                            : Pigment.inkMute,
                                      ),
                                    ),
                                    Text(
                                      codex.synergies.contains(s.command)
                                          ? '${s.requirement} — ${s.blurb}'
                                          : 'Two pure traits, doubled up.',
                                      style: Face.text(10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlleleLine extends StatelessWidget {
  const _AlleleLine({required this.allele, required this.known});
  final Allele allele;
  final bool known;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlleleMark(allele: allele, known: known, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      known ? allele.name : 'Unidentified',
                      style: Face.title(
                        12.5,
                        color: known ? Pigment.ink : Pigment.inkMute,
                      ),
                    ),
                    if (allele.isRecessive) ...[
                      const SizedBox(width: 6),
                      Text('recessive', style: Face.label(8)),
                    ],
                  ],
                ),
                if (known) ...[
                  Text(allele.blurb, style: Face.text(10)),
                  Text(
                    'Expressed: ${allele.mods.describe()} · '
                    'Pure: ${allele.pureMods.describe()}',
                    style: Face.text(9.5, color: Pigment.inkMute),
                  ),
                ] else
                  Text(
                    'Hatch a pure bird or buy a gene read.',
                    style: Face.text(10, color: Pigment.inkMute),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManeuversTab extends StatelessWidget {
  const _ManeuversTab({required this.known});
  final Set<String> known;

  @override
  Widget build(BuildContext context) {
    final all = Maneuvers.all;
    return Pane(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaneTitle(
            'Commands',
            subtitle: '${known.length} of ${all.length} seen in a race',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.1,
              ),
              itemCount: all.length,
              itemBuilder: (context, i) {
                final command = all[i];
                if (!known.contains(command.id)) {
                  return Pane(
                    padding: const EdgeInsets.all(9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: Pigment.inkMute,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Not yet raced. ${command.origin.label} command.',
                            style: Face.text(10, color: Pigment.inkMute),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ManeuverTile(command: command);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTab extends StatelessWidget {
  const _CourseTab({required this.known});
  final Set<String> known;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 3.0,
      ),
      itemCount: Venue.all.length,
      itemBuilder: (context, i) {
        final venue = Venue.all[i];
        final seen = known.contains(venue.id);
        return Pane(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: seen
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        )
                      : const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: Image.asset(
                    venue.scenePlate,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      venue.name,
                      style: Face.title(
                        14,
                        color: seen ? Pigment.ink : Pigment.inkMute,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seen ? venue.blurb : 'Not yet raced.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Face.text(10.5),
                    ),
                    if (seen) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${venue.segments} segments · field of '
                        '${venue.fieldSize}',
                        style: Face.text(9.5, color: Pigment.inkMute),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldTab extends StatelessWidget {
  const _FieldTab({required this.known, required this.champions});
  final Set<String> known;
  final Set<String> champions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Pane(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                Text('ARCHETYPES', style: Face.label(9)),
                const SizedBox(height: 8),
                for (final a in Archetype.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          known.contains(a.id)
                              ? Icons.visibility_rounded
                              : Icons.lock_outline_rounded,
                          size: 14,
                          color: known.contains(a.id)
                              ? Pigment.momentum
                              : Pigment.inkMute,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: Face.title(13)),
                              Text(
                                known.contains(a.id)
                                    ? a.blurb
                                    : 'Not yet raced against.',
                                style: Face.text(10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Pane(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                Text('CHAMPIONS', style: Face.label(9)),
                const SizedBox(height: 8),
                for (final c in Champion.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              champions.contains(c.id)
                                  ? Icons.emoji_events_rounded
                                  : Icons.lock_outline_rounded,
                              size: 15,
                              color: champions.contains(c.id)
                                  ? Pigment.amber
                                  : Pigment.inkMute,
                            ),
                            const SizedBox(width: 7),
                            Text(c.name, style: Face.title(14)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: Face.text(10.5, color: Pigment.amber),
                              ),
                              Text(
                                champions.contains(c.id)
                                    ? c.blurb
                                    : 'Beaten by nobody in your stable yet.',
                                style: Face.text(10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GearTab extends StatelessWidget {
  const _GearTab({required this.known});
  final Set<String> known;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: Tack.all.length,
      itemBuilder: (context, i) {
        final tack = Tack.all[i];
        final seen = known.contains(tack.id);
        return Pane(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Opacity(
                opacity: seen ? 1 : 0.3,
                child: Image.asset(tack.iconPath, width: 30, height: 30),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seen ? tack.name : '???',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Face.title(
                        11.5,
                        color: seen ? Pigment.ink : Pigment.inkMute,
                      ),
                    ),
                    Text(
                      seen ? tack.mods.describe() : 'Never handled.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Face.text(9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
