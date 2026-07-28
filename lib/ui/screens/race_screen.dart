import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/typography.dart';
import '../../race/command_library.dart';
import '../../season/season_map.dart';
import '../../race/race_engine.dart';
import '../../state/game.dart';
import '../../tutorial/lesson.dart';
import '../widgets/bird_view.dart';
import '../widgets/coach_mark.dart';
import '../widgets/command_card.dart';
import '../widgets/race_view.dart';
import '../widgets/ui_kit.dart';
import 'result_screen.dart';

class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  /// Index of the card awaiting a lane choice, if any.
  int? _awaitingLaneFor;
  bool _resultShown = false;

  final GlobalKey _terrainKey = GlobalKey();
  final GlobalKey _laneKey = GlobalKey();
  final GlobalKey _birdKey = GlobalKey();
  final GlobalKey _handKey = GlobalKey();
  final GlobalKey _turnKey = GlobalKey();

  late final bool _teaching = context.read<Game>().needsLesson(Lesson.race);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final engine = game.engine;
    final node = game.activeNode;

    if (engine == null || node == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CoachOverlay(
      active: _teaching,
      onDone: () => game.completeLesson(Lesson.race),
      steps: [
        CoachStep(
          anchor: _terrainKey,
          icon: Icons.terrain_rounded,
          title: 'The ground ahead',
          body:
              'Every segment of the track is drawn before you reach it. Mud '
              'taxes stamina, puddles kill momentum, hay costs ground without '
              'grip, and a downhill is free speed. Plan two segments out.',
        ),
        CoachStep(
          anchor: _laneKey,
          icon: Icons.swap_vert_rounded,
          title: 'Three lanes, and a draft',
          body:
              'Rivals show the intent they will resolve at the end of the turn, '
              'so you can see the move coming. Tuck in directly behind one in '
              'the same lane and the wind does part of your work.',
        ),
        CoachStep(
          anchor: _birdKey,
          icon: Icons.favorite_rounded,
          title: 'Stamina, Effort, Momentum',
          body:
              'Effort is how many commands you can play this turn and it comes '
              'back every turn. Stamina does not. Momentum adds free ground, but '
              'a corner charges you for whatever exceeds your control.',
        ),
        CoachStep(
          anchor: _handKey,
          icon: Icons.style_rounded,
          title: 'This is your genome',
          body:
              'Every card here was granted by an allele your bird carries. A '
              'greyed-out card is one you cannot afford right now — read the '
              'cost in the corner before you spend.',
        ),
        CoachStep(
          anchor: _turnKey,
          icon: Icons.skip_next_rounded,
          title: 'End the turn when ready',
          body:
              'Nothing moves until you do. Passing with Effort in hand is often '
              'right: stamina you keep now is ground you take on the last lap.',
        ),
      ],
      child: _buildScreen(context, game, engine, node),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    Game game,
    RaceEngine engine,
    SeasonNode node,
  ) {
    if (engine.phase == RacePhase.finished && !_resultShown) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(gameRoute(const ResultScreen()));
      });
    }

    final player = engine.player;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(node.venue.plate, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.pitch.withValues(alpha: 0.72),
                  Palette.pitch.withValues(alpha: 0.55),
                  Palette.pitch.withValues(alpha: 0.93),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: LayoutBuilder(
                builder: (context, box) => Column(
                  children: [
                    _Header(
                      engine: engine,
                      venueName: node.venue.name,
                      eventName: node.kind.label,
                    ),
                    const SizedBox(height: 8),
                    TrackStrip(
                      key: _terrainKey,
                      track: engine.track,
                      distance: player.distance,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: LaneField(
                              key: _laneKey,
                              engine: engine,
                              highlightLane: _awaitingLaneFor == null
                                  ? null
                                  : player.lane,
                              onLaneTap: _awaitingLaneFor == null
                                  ? null
                                  : (lane) => _playWithLane(game, lane),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: Panel(
                              padding: const EdgeInsets.all(9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('COMMENTARY', style: Type.label(8.5)),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      reverse: true,
                                      child: RaceLog(lines: engine.log_),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Dashboard(
                      engine: engine,
                      birdKey: _birdKey,
                      handKey: _handKey,
                      turnKey: _turnKey,
                      // The hand and the track have to share a landscape phone,
                      // so the dashboard takes a share of the height rather than
                      // a fixed slice that would squeeze the lanes to nothing.
                      height: (box.maxHeight * 0.44).clamp(132.0, 190.0),
                      awaitingLane: _awaitingLaneFor != null,
                      onCancelLane: () =>
                          setState(() => _awaitingLaneFor = null),
                      onPlay: (index) => _onCardTap(game, index),
                      onEndTurn: () {
                        setState(() => _awaitingLaneFor = null);
                        game.endTurn();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCardTap(Game game, int index) {
    final engine = game.engine;
    if (engine == null || !engine.canPlay(index)) return;
    final command = Commands.byId(engine.hand[index]);
    if (command.needsLane) {
      setState(() => _awaitingLaneFor = index);
      return;
    }
    game.playCommand(index);
  }

  void _playWithLane(Game game, int lane) {
    final index = _awaitingLaneFor;
    if (index == null) return;
    setState(() => _awaitingLaneFor = null);
    game.playCommand(index, lane: lane);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.engine,
    required this.venueName,
    required this.eventName,
  });

  final RaceEngine engine;
  final String venueName;
  final String eventName;

  @override
  Widget build(BuildContext context) {
    final remaining = (engine.track.totalLength - engine.player.distance).clamp(
      0,
      99999,
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venueName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.title(17),
              ),
              Text(
                '$eventName · lap ${engine.track.laps}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.text(10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatChip(
          label: 'pos',
          value: '${engine.playerPosition}/${engine.entrants.length}',
          icon: Icons.leaderboard,
          compact: true,
        ),
        const SizedBox(width: 6),
        StatChip(
          label: 'turn',
          value: '${engine.turn}',
          icon: Icons.hourglass_bottom,
          tint: Palette.inkSoft,
          compact: true,
        ),
        const SizedBox(width: 6),
        StatChip(
          label: 'to go',
          value: '${remaining.round()}',
          icon: Icons.flag,
          tint: Palette.momentum,
          compact: true,
        ),
      ],
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.engine,
    required this.height,
    required this.awaitingLane,
    required this.onCancelLane,
    required this.onPlay,
    required this.onEndTurn,
    required this.birdKey,
    required this.handKey,
    required this.turnKey,
  });

  final RaceEngine engine;
  final double height;

  /// Anchors for the first-race walkthrough.
  final GlobalKey birdKey;
  final GlobalKey handKey;
  final GlobalKey turnKey;
  final bool awaitingLane;
  final VoidCallback onCancelLane;
  final ValueChanged<int> onPlay;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    final player = engine.player;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 196,
            child: Panel(
              key: birdKey,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BirdView(
                          pose: player.pose,
                          plume: player.plume,
                          size: 34,
                          showPlume: false,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            player.name,
                            overflow: TextOverflow.ellipsis,
                            style: Type.title(14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    MeterBar(
                      value: player.stamina,
                      max: player.staminaMax,
                      tint: player.stamina < player.staminaMax * 0.25
                          ? Palette.staminaLow
                          : Palette.stamina,
                      label: 'Stamina',
                      height: 9,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('EFFORT', style: Type.label(8.5)),
                        const SizedBox(width: 6),
                        PipRow(
                          filled: engine.effort,
                          total: player.effortMax,
                          tint: Palette.effort,
                          size: 10,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('MOMENTUM', style: Type.label(8.5)),
                        const SizedBox(width: 6),
                        PipRow(
                          filled: player.momentum,
                          total: RaceEngine.momentumCap,
                          tint: Palette.momentum,
                          size: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    StatusRow(entrant: player),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        awaitingLane
                            ? 'Pick a lane on the track above'
                            : 'HAND · ${engine.hand.length} in hand,'
                                  ' ${engine.deck.length} in deck',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.text(
                          11,
                          color: awaitingLane ? Palette.amber : Palette.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (awaitingLane)
                      GhostButton(
                        key: turnKey,
                        label: 'Cancel',
                        compact: true,
                        tint: Palette.bad,
                        onTap: onCancelLane,
                      )
                    else
                      PrimaryButton(
                        key: turnKey,
                        label: 'End Turn',
                        icon: Icons.skip_next_rounded,
                        compact: true,
                        onTap: onEndTurn,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  key: handKey,
                  child: engine.hand.isEmpty
                      ? const EmptyNote(
                          'No commands left this turn.',
                          icon: Icons.style_outlined,
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: engine.hand.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 7),
                          itemBuilder: (context, i) => CommandCard(
                            command: Commands.byId(engine.hand[i]),
                            playable: engine.canPlay(i),
                            onTap: () => onPlay(i),
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
