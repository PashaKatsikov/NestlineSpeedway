import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../genetics/genome.dart';
import '../../genetics/locus.dart';
import '../../race/command.dart';
import '../../race/command_library.dart';
import '../../race/rival.dart';
import '../../race/track.dart';
import '../../season/items.dart';
import '../../state/game.dart';
import '../widgets/command_card.dart';
import '../widgets/genome_view.dart';
import '../widgets/ui_kit.dart';

/// The record: alleles, synergies, commands, venues, rivals and tack.
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
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
    final game = context.watch<Game>();
    final codex = game.stable.codex;

    return GameScreen(
      title: 'Codex',
      subtitle:
          '${codex.completion}% recorded · '
          '${codex.alleles.length} of ${codex.alleleTotal} alleles identified',
      plate: Plates.scene(7),
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                GhostButton(
                  label: _tabs[i],
                  compact: true,
                  tint: _tab == i ? Palette.amber : Palette.inkMute,
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

  Widget _body(Game game) {
    final codex = game.stable.codex;
    return switch (_tab) {
      0 => _GeneticsTab(game: game),
      1 => _CommandsTab(known: codex.commands),
      2 => _VenuesTab(known: codex.venues),
      3 => _RivalsTab(known: codex.rivals, champions: codex.champions),
      _ => _TackTab(known: codex.tack),
    };
  }
}

class _GeneticsTab extends StatelessWidget {
  const _GeneticsTab({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final codex = game.stable.codex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Panel(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                for (final l in Locus.values) ...[
                  Text(l.label.toUpperCase(), style: Type.label(9)),
                  Text(l.governs, style: Type.text(10.5)),
                  const SizedBox(height: 6),
                  for (final allele in l.alleles)
                    _AlleleRow(
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
          child: Panel(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'Synergies',
                  subtitle:
                      '${codex.synergies.length} of '
                      '${Synergies.all.length} found',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      for (final s in Synergies.all)
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
                                    ? Palette.schoolRainbow
                                    : Palette.inkMute,
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
                                      style: Type.title(
                                        12,
                                        color:
                                            codex.synergies.contains(s.command)
                                            ? Palette.schoolRainbow
                                            : Palette.inkMute,
                                      ),
                                    ),
                                    Text(
                                      codex.synergies.contains(s.command)
                                          ? '${s.requirement} — ${s.blurb}'
                                          : 'Two pure traits, doubled up.',
                                      style: Type.text(10),
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

class _AlleleRow extends StatelessWidget {
  const _AlleleRow({required this.allele, required this.known});
  final Allele allele;
  final bool known;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlleleChip(allele: allele, known: known, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      known ? allele.name : 'Unidentified',
                      style: Type.title(
                        12.5,
                        color: known ? Palette.ink : Palette.inkMute,
                      ),
                    ),
                    if (allele.isRecessive) ...[
                      const SizedBox(width: 6),
                      Text('recessive', style: Type.label(8)),
                    ],
                  ],
                ),
                if (known) ...[
                  Text(allele.blurb, style: Type.text(10)),
                  Text(
                    'Expressed: ${allele.mods.describe()} · '
                    'Pure: ${allele.pureMods.describe()}',
                    style: Type.text(9.5, color: Palette.inkMute),
                  ),
                ] else
                  Text(
                    'Hatch a pure bird or buy a gene read.',
                    style: Type.text(10, color: Palette.inkMute),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandsTab extends StatelessWidget {
  const _CommandsTab({required this.known});
  final Set<String> known;

  @override
  Widget build(BuildContext context) {
    final all = Commands.all;
    return Panel(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
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
                  return Panel(
                    padding: const EdgeInsets.all(9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: Palette.inkMute,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Not yet raced. ${command.origin.label} command.',
                            style: Type.text(10, color: Palette.inkMute),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return CommandTile(command: command);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesTab extends StatelessWidget {
  const _VenuesTab({required this.known});
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
        return Panel(
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
                      style: Type.title(
                        14,
                        color: seen ? Palette.ink : Palette.inkMute,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seen ? venue.blurb : 'Not yet raced.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Type.text(10.5),
                    ),
                    if (seen) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${venue.segments} segments · field of '
                        '${venue.fieldSize}',
                        style: Type.text(9.5, color: Palette.inkMute),
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

class _RivalsTab extends StatelessWidget {
  const _RivalsTab({required this.known, required this.champions});
  final Set<String> known;
  final Set<String> champions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                Text('ARCHETYPES', style: Type.label(9)),
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
                              ? Palette.momentum
                              : Palette.inkMute,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: Type.title(13)),
                              Text(
                                known.contains(a.id)
                                    ? a.blurb
                                    : 'Not yet raced against.',
                                style: Type.text(10.5),
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
          child: Panel(
            padding: const EdgeInsets.all(11),
            child: ListView(
              children: [
                Text('CHAMPIONS', style: Type.label(9)),
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
                                  ? Palette.amber
                                  : Palette.inkMute,
                            ),
                            const SizedBox(width: 7),
                            Text(c.name, style: Type.title(14)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: Type.text(10.5, color: Palette.amber),
                              ),
                              Text(
                                champions.contains(c.id)
                                    ? c.blurb
                                    : 'Beaten by nobody in your stable yet.',
                                style: Type.text(10.5),
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

class _TackTab extends StatelessWidget {
  const _TackTab({required this.known});
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
        return Panel(
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
                      style: Type.title(
                        11.5,
                        color: seen ? Palette.ink : Palette.inkMute,
                      ),
                    ),
                    Text(
                      seen ? tack.mods.describe() : 'Never handled.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Type.text(9.5),
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
