import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../genetics/hatchery.dart';
import '../../race/command_library.dart';
import '../../season/season_map.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/command_card.dart';
import '../widgets/genome_view.dart';
import '../widgets/ui_kit.dart';

/// The opening walkthrough: five pages that each say one thing and show it.
///
/// Shown once on the first run and replayable from Settings. The illustrations
/// are the real widgets from the game rather than pictures of them, so the
/// player recognises them the moment they appear in a race.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  static const List<_Chapter> _chapters = [
    _Chapter(
      title: 'You never steer',
      body:
          'A race is turn-based. Each turn you spend Effort playing commands '
          'from your bird\'s hand, and then every rival resolves the intent it '
          'already showed you. No reflexes, all reading.',
      art: _CommandsArt(),
    ),
    _Chapter(
      title: 'Your deck is a genome',
      body:
          'Commands are not drafted from a reward screen. Every bird carries six '
          'gene loci, and each expressed allele grants one command. Two matching '
          'copies grant a stronger signature command instead.',
      art: _GenomeArt(),
    ),
    _Chapter(
      title: 'Stamina is the real race',
      body:
          'Moving costs stamina, and sitting directly behind a rival in the same '
          'lane cuts that cost by a third. Run it to zero and your bird is '
          'Blown: half the ground, one less Effort, and a real risk of injury.',
      art: _StaminaArt(),
    ),
    _Chapter(
      title: 'Breed for the deck you want',
      body:
          'Podiums pay eggs, and eggs hatch chicks from a pair you choose. The '
          'best commands sit on recessives that only express when doubled up — '
          'and doubling up means pairing relatives, which hatches frail birds.',
      art: _BreedingArt(),
    ),
    _Chapter(
      title: 'A season is a route',
      body:
          'Twelve events, and you pick the path through them. Races pay, traders '
          'sell tack, rest days undo fatigue. At the end sits a Grand Prix with a '
          'champion already in it.',
      art: _RouteArt(),
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _chapters.length - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    context.read<Game>().completeIntro();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _chapters.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Plates.trackAutumn, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.pitch.withValues(alpha: 0.86),
                  Palette.pitch.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'How Nestline Speedway works',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Type.title(19),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GhostButton(
                        label: last ? 'Close' : 'Skip',
                        compact: true,
                        onTap: _finish,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemCount: _chapters.length,
                      itemBuilder: (context, i) => _ChapterView(
                        chapter: _chapters[i],
                        number: i + 1,
                        total: _chapters.length,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Dots(count: _chapters.length, active: _page),
                      const Spacer(),
                      PrimaryButton(
                        label: last ? 'Enter the stable' : 'Next',
                        icon: last
                            ? Icons.play_arrow_rounded
                            : Icons.arrow_forward_rounded,
                        compact: true,
                        onTap: _next,
                      ),
                    ],
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

class _Chapter {
  const _Chapter({required this.title, required this.body, required this.art});

  final String title;
  final String body;
  final Widget art;
}

class _ChapterView extends StatelessWidget {
  const _ChapterView({
    required this.chapter,
    required this.number,
    required this.total,
  });

  final _Chapter chapter;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAPTER $number OF $total',
                    style: Type.label(9, color: Palette.amber),
                  ),
                  const SizedBox(height: 7),
                  Text(chapter.title, style: Type.title(25)),
                  const SizedBox(height: 9),
                  Text(chapter.body, style: Type.text(12.5, height: 1.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Panel(
            padding: const EdgeInsets.all(12),
            child: Center(child: chapter.art),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: 6),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? Palette.amber : Palette.slateHi,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ chapter art

/// Three real command cards, fanned.
class _CommandsArt extends StatelessWidget {
  const _CommandsArt();

  static const List<String> _ids = ['push', 'draft', 'hold_line'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // The cards are drawn at their real size and then scaled to whatever the
        // panel has, so the layout never has to fight the card's own metrics.
        const spread = 3 * 104.0;
        final scale = (box.maxWidth / spread).clamp(0.55, 1.0);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            // Cards read as cards at roughly the height they have in a hand;
            // stretched to a whole panel they read as columns.
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _ids.length; i++)
                  Transform.rotate(
                    angle: (i - 1) * 0.075,
                    child: Padding(
                      padding: EdgeInsets.only(top: i == 1 ? 0 : 12),
                      child: CommandCard(
                        command: Commands.byId(_ids[i]),
                        width: 104,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The genome of a bird that is actually in the player's stable.
class _GenomeArt extends StatelessWidget {
  const _GenomeArt();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final racer = game.stable.racers.isEmpty ? null : game.stable.racers.first;
    if (racer == null) {
      return const EmptyNote('Your first birds are on their way.');
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            BirdView(pose: racer.portraitPose, plume: racer.plume, size: 46),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(racer.name, style: Type.title(15)),
                  Text(
                    racer.genome.notation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Type.text(9.5, color: Palette.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Flexible(
          child: SingleChildScrollView(
            child: GenomeStrip(
              racer: racer,
              codex: game.stable.codex,
              dense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// A stamina bar draining, with the cost of the move that drained it.
class _StaminaArt extends StatefulWidget {
  const _StaminaArt();

  @override
  State<_StaminaArt> createState() => _StaminaArtState();
}

class _StaminaArtState extends State<_StaminaArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _drain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drain,
      builder: (context, _) {
        // Full, then spent, then a little back: the shape of every race.
        final t = _drain.value;
        final stamina = t < 0.75 ? 14 - (t / 0.75) * 13 : 1 + (t - 0.75) * 12;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeterBar(
              value: stamina.round(),
              max: 14,
              tint: stamina < 4 ? Palette.staminaLow : Palette.stamina,
              label: stamina < 2 ? 'Blown' : 'Stamina',
              height: 12,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Cost(
                    label: 'In the open',
                    value: '−3',
                    tint: Palette.staminaLow,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Cost(
                    label: 'In the draft',
                    value: '−2',
                    tint: Palette.stamina,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BirdView(
                  pose: Sprites.poseSprint,
                  plume: 3,
                  size: 44,
                  showPlume: false,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.air_rounded,
                  size: 18,
                  color: Palette.momentum.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                const BirdView(
                  pose: Sprites.poseStrut,
                  plume: 8,
                  size: 44,
                  showPlume: false,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'The bird behind pays less for the same ground.',
              textAlign: TextAlign.center,
              style: Type.text(10.5, color: Palette.inkMute),
            ),
          ],
        );
      },
    );
  }
}

class _Cost extends StatelessWidget {
  const _Cost({required this.label, required this.value, required this.tint});

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Shape.rSm),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(value, style: Type.number(17, color: tint)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Type.text(10, color: Palette.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Two parents, an egg, a chick.
class _BreedingArt extends StatelessWidget {
  const _BreedingArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BirdView(pose: Sprites.poseReady, plume: 2, size: 52),
            const _Glyph(Icons.add_rounded),
            const BirdView(pose: Sprites.poseCalm, plume: 11, size: 52),
            const _Glyph(Icons.arrow_forward_rounded),
            Image.asset(Sprites.egg(3), width: 44, height: 44),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final tier in EggTier.all.take(4))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Palette.pitch.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Shape.rSm),
                  border: Border.all(
                    color: Palette.tiers[tier.index].withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(Sprites.egg(tier.index), width: 18, height: 18),
                    const SizedBox(width: 5),
                    Text(
                      tier.name,
                      style: Type.text(10, color: Palette.tiers[tier.index]),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'A better shell rescues more recessives and mutates more often.',
          textAlign: TextAlign.center,
          style: Type.text(10.5, color: Palette.inkMute),
        ),
      ],
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Icon(icon, size: 17, color: Palette.inkMute),
    );
  }
}

/// A short stretch of schedule, drawn the way the season map draws it.
class _RouteArt extends StatelessWidget {
  const _RouteArt();

  static const List<NodeKind> _route = [
    NodeKind.sprint,
    NodeKind.trader,
    NodeKind.endurance,
    NodeKind.rest,
    NodeKind.grandPrix,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _route.length; i++) ...[
            _RouteRow(kind: _route[i], open: i == 0),
            if (i < _route.length - 1)
              Icon(
                Icons.more_vert_rounded,
                size: 15,
                color: Palette.inkMute.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.kind, required this.open});

  final NodeKind kind;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final tint = kind.tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.asphaltHi,
        borderRadius: BorderRadius.circular(Shape.rSm),
        border: Border.all(
          color: open ? tint : Palette.slate,
          width: open ? 2 : 1,
        ),
        boxShadow: open ? Shape.glow(tint, 0.35) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 16, color: open ? tint : Palette.inkMute),
          const SizedBox(width: 7),
          Text(
            kind.label,
            style: Type.text(11, color: open ? Palette.ink : Palette.inkSoft),
          ),
        ],
      ),
    );
  }
}
