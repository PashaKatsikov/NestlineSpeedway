import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// How the game works, in the player's own language. Doubles as the rules
/// reference, which is why it is reachable from Settings during a season.
class PrimerScreen extends StatelessWidget {
  const PrimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stage(
      title: 'How Nestline Speedway works',
      plate: Backdrops.scene(5),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Pane(
              child: ListView(
                children: const [
                  _Rule(
                    'You never steer',
                    'A race is turn-based. Each turn you spend Effort playing '
                        'commands drawn from your bird\'s deck, then every rival '
                        'resolves the intent they already showed you.',
                  ),
                  _Rule(
                    'Stamina is the real race',
                    'Moving costs stamina. Sitting directly behind a rival in '
                        'the same lane cuts that cost by a third. At zero '
                        'stamina your bird is Blown: half ground, one less '
                        'effort, and a real chance of injury.',
                  ),
                  _Rule(
                    'Momentum cuts both ways',
                    'Every Move adds momentum and momentum adds free ground. '
                        'But a corner burns stamina equal to whatever momentum '
                        'exceeds your control, so leading into a corner at full '
                        'tilt is how races are lost.',
                  ),
                  _Rule(
                    'Read the terrain strip',
                    'Mud taxes stamina, gravel ruffles, puddles kill momentum, '
                        'hay bales cost ground without grip, downhills are free '
                        'speed. The strip along the top always shows what is '
                        'coming.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Pane(
              child: ListView(
                children: [
                  const _Rule(
                    'Your deck is a genome',
                    'Commands are not drafted from a reward screen. Each bird '
                        'has six gene loci, and each expressed allele grants a '
                        'command. Homozygous loci grant a stronger signature '
                        'command, and certain pairs of pure traits unlock a '
                        'synergy.',
                  ),
                  const _Rule(
                    'Recessives are the prize',
                    'The best commands sit on recessive alleles, which only '
                        'express when a bird carries two copies. Carriers show '
                        'the dominant phenotype, so you have to track what your '
                        'line is hiding.',
                  ),
                  const _Rule(
                    'Inbreeding is the price',
                    'Doubling up recessives means pairing relatives. Past an '
                        'inbreeding coefficient of 0.25 a chick is Frail; past '
                        '0.375 she hatches weak as well. Outside stock from '
                        'Traders is how you reset a tight line.',
                  ),
                  const _Rule(
                    'Injuries are permanent',
                    'What a bird picks up on the circuit follows her home. A '
                        'torn tendon ends a career. Eggs, purses and the Codex '
                        'survive the season; the bird might not.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made offline: no ads, no in-app purchases, no accounts, '
                    'no analytics, no network calls during play.',
                    style: Face.text(11, color: Pigment.inkMute),
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

class _Rule extends StatelessWidget {
  const _Rule(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Face.title(15, color: Pigment.amber)),
          const SizedBox(height: 3),
          Text(body, style: Face.text(11.5, height: 1.4)),
        ],
      ),
    );
  }
}
