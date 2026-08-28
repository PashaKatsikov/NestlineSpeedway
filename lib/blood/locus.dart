import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';

/// The six gene loci. Order matters: it defines the layout of [Heredity.alleles]
/// and the order alleles are shown in the Brooder, so never reorder without a
/// save migration.
enum Locus { stride, wind, temper, plumage, comb, claw }

extension LocusInfo on Locus {
  String get label => switch (this) {
    Locus.stride => 'Stride',
    Locus.wind => 'Wind',
    Locus.temper => 'Temper',
    Locus.plumage => 'Plumage',
    Locus.comb => 'Comb',
    Locus.claw => 'Claw',
  };

  String get governs => switch (this) {
    Locus.stride => 'Ground covered by each Move command',
    Locus.wind => 'Stamina pool and how fast it comes back',
    Locus.temper => 'Momentum control and access to risky commands',
    Locus.plumage => 'Command school and racing silks',
    Locus.comb => 'Effort available each turn',
    Locus.claw => 'Grip on rough terrain and lane changes',
  };

  List<Allele> get alleles => Alleles.of(this);
}

/// A single allele. Alleles within a locus are ordered by dominance — index 0
/// is fully dominant, the last index is fully recessive. Recessive alleles carry
/// the more extreme modifiers and the better signature commands, which is what
/// makes them worth breeding toward.
@immutable
class Allele {
  const Allele({
    required this.locus,
    required this.index,
    required this.code,
    required this.name,
    required this.blurb,
    required this.mods,
    required this.pureMods,
    required this.traitCommand,
    required this.signatureCommand,
  });

  final Locus locus;

  /// Dominance rank within the locus; lower wins.
  final int index;

  /// Single-letter pedigree code. Uppercase for dominant, lowercase for
  /// recessive, following livestock notation.
  final String code;

  final String name;
  final String blurb;

  /// Applied when this allele is the expressed one.
  final StatMods mods;

  /// Applied *in addition* when the bird is homozygous for this allele.
  final StatMods pureMods;

  /// Maneuver granted when expressed.
  final String traitCommand;

  /// Maneuver granted only when homozygous.
  final String signatureCommand;

  bool get isRecessive => index == locus.alleles.length - 1;

  Color get tint => switch (locus) {
    Locus.stride => Pigment.distance,
    Locus.wind => Pigment.stamina,
    Locus.temper => Pigment.ember,
    Locus.plumage => Pigment.schoolRainbow,
    Locus.comb => Pigment.effort,
    Locus.claw => Pigment.momentum,
  };

  @override
  String toString() => code;
}

/// Additive stat modifiers contributed by an allele.
@immutable
class StatMods {
  const StatMods({
    this.stamina = 0,
    this.stride = 0,
    this.effort = 0,
    this.grip = 0,
    this.control = 0,
    this.recovery = 0,
    this.hand = 0,
    this.momentumGain = 0,
  });

  final int stamina;
  final int stride;
  final int effort;
  final int grip;
  final int control;
  final int recovery;
  final int hand;
  final int momentumGain;

  StatMods operator +(StatMods o) => StatMods(
    stamina: stamina + o.stamina,
    stride: stride + o.stride,
    effort: effort + o.effort,
    grip: grip + o.grip,
    control: control + o.control,
    recovery: recovery + o.recovery,
    hand: hand + o.hand,
    momentumGain: momentumGain + o.momentumGain,
  );

  /// Compact human-readable summary, used in the Brooder and Ledger.
  String describe() {
    final parts = <String>[];
    void add(int v, String name) {
      if (v != 0) parts.add('${v > 0 ? '+' : ''}$v $name');
    }

    add(stamina, 'stamina');
    add(stride, 'stride');
    add(effort, 'effort');
    add(grip, 'grip');
    add(control, 'control');
    add(recovery, 'recovery');
    add(hand, 'hand');
    add(momentumGain, 'momentum');
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

/// The authored allele tables.
class Alleles {
  Alleles._();

  static const List<Allele> stride = [
    Allele(
      locus: Locus.stride,
      index: 0,
      code: 'L',
      name: 'Long',
      blurb: 'Reaching gait that eats up straights.',
      mods: StatMods(stride: 2),
      pureMods: StatMods(stride: 1),
      traitCommand: 'stretch_out',
      signatureCommand: 'ground_eater',
    ),
    Allele(
      locus: Locus.stride,
      index: 1,
      code: 'S',
      name: 'Short',
      blurb: 'Quick, tidy steps. Easy to place on a corner.',
      mods: StatMods(stride: 1, control: 1),
      pureMods: StatMods(control: 1, hand: 1),
      traitCommand: 'tidy_feet',
      signatureCommand: 'inside_shuffle',
    ),
    Allele(
      locus: Locus.stride,
      index: 2,
      code: 'b',
      name: 'Bounding',
      blurb: 'Hops rather than runs. Slow to start, brutal once rolling.',
      mods: StatMods(momentumGain: 1),
      pureMods: StatMods(momentumGain: 1, stride: 1),
      traitCommand: 'gather',
      signatureCommand: 'bound',
    ),
  ];

  static const List<Allele> wind = [
    Allele(
      locus: Locus.wind,
      index: 0,
      code: 'D',
      name: 'Deep',
      blurb: 'A vast tank. Can afford mistakes.',
      mods: StatMods(stamina: 18),
      pureMods: StatMods(stamina: 8),
      traitCommand: 'lung_up',
      signatureCommand: 'bottomless',
    ),
    Allele(
      locus: Locus.wind,
      index: 1,
      code: 'E',
      name: 'Even',
      blurb: 'Modest tank, refills willingly.',
      mods: StatMods(stamina: 10, recovery: 2),
      pureMods: StatMods(recovery: 2),
      traitCommand: 'settle',
      signatureCommand: 'metronome',
    ),
    Allele(
      locus: Locus.wind,
      index: 2,
      code: 's',
      name: 'Shallow',
      blurb: 'Tiny tank that snaps back from nothing.',
      mods: StatMods(stamina: 2, recovery: 5),
      pureMods: StatMods(recovery: 3),
      traitCommand: 'snatch_air',
      signatureCommand: 'second_wind',
    ),
  ];

  static const List<Allele> temper = [
    Allele(
      locus: Locus.temper,
      index: 0,
      code: 'T',
      name: 'Steady',
      blurb: 'Never overcooks a corner.',
      mods: StatMods(control: 2),
      pureMods: StatMods(control: 1, stamina: 4),
      traitCommand: 'measure',
      signatureCommand: 'ice_line',
    ),
    Allele(
      locus: Locus.temper,
      index: 1,
      code: 'e',
      name: 'Eager',
      blurb: 'Wants the front. Pays for it later.',
      mods: StatMods(stride: 1),
      pureMods: StatMods(stride: 1, momentumGain: 1),
      traitCommand: 'press_on',
      signatureCommand: 'front_run',
    ),
    Allele(
      locus: Locus.temper,
      index: 2,
      code: 'w',
      name: 'Wild',
      blurb: 'Enormous speed, no brakes, no sense.',
      mods: StatMods(stride: 2, control: -1),
      pureMods: StatMods(stride: 1, momentumGain: 1, control: -1),
      traitCommand: 'bolt',
      signatureCommand: 'wild_kick',
    ),
  ];

  static const List<Allele> plumage = [
    Allele(
      locus: Locus.plumage,
      index: 0,
      code: 'P',
      name: 'Speckled',
      blurb: 'Farmyard hardiness. Grips anything.',
      mods: StatMods(grip: 1),
      pureMods: StatMods(grip: 1, stamina: 4),
      traitCommand: 'dig_in',
      signatureCommand: 'mudlark',
    ),
    Allele(
      locus: Locus.plumage,
      index: 1,
      code: 'G',
      name: 'Gold',
      blurb: 'Show bird stock. Thrives on a crowd.',
      mods: StatMods(stamina: 6),
      pureMods: StatMods(stamina: 4, recovery: 1),
      traitCommand: 'play_crowd',
      signatureCommand: 'golden_hour',
    ),
    Allele(
      locus: Locus.plumage,
      index: 2,
      code: 'W',
      name: 'White',
      blurb: 'Clean, efficient, unfussy.',
      mods: StatMods(recovery: 2),
      pureMods: StatMods(recovery: 1, hand: 1),
      traitCommand: 'clean_line',
      signatureCommand: 'white_flash',
    ),
    Allele(
      locus: Locus.plumage,
      index: 3,
      code: 'r',
      name: 'Rainbow',
      blurb: 'Impossible plumage, impossible instincts.',
      mods: StatMods(hand: 1),
      pureMods: StatMods(hand: 1, effort: 1),
      traitCommand: 'shimmer',
      signatureCommand: 'prism_run',
    ),
  ];

  static const List<Allele> comb = [
    Allele(
      locus: Locus.comb,
      index: 0,
      code: 'C',
      name: 'Single',
      blurb: 'Standard issue. Reliable.',
      mods: StatMods(),
      pureMods: StatMods(stamina: 4),
      traitCommand: 'compose',
      signatureCommand: 'workhorse',
    ),
    Allele(
      locus: Locus.comb,
      index: 1,
      code: 'o',
      name: 'Rose',
      blurb: 'Reads the race a beat early.',
      mods: StatMods(hand: 1),
      pureMods: StatMods(hand: 1),
      traitCommand: 'read_race',
      signatureCommand: 'rose_gambit',
    ),
    Allele(
      locus: Locus.comb,
      index: 2,
      code: 'n',
      name: 'Crown',
      blurb: 'Runs on something other than air.',
      mods: StatMods(effort: 1),
      pureMods: StatMods(effort: 1),
      traitCommand: 'crown_surge',
      signatureCommand: 'coronation',
    ),
  ];

  static const List<Allele> claw = [
    Allele(
      locus: Locus.claw,
      index: 0,
      code: 'B',
      name: 'Broad',
      blurb: 'Wide pad, plenty of purchase.',
      mods: StatMods(grip: 1),
      pureMods: StatMods(grip: 1),
      traitCommand: 'plant_foot',
      signatureCommand: 'anchor',
    ),
    Allele(
      locus: Locus.claw,
      index: 1,
      code: 'f',
      name: 'Fine',
      blurb: 'Delicate toes that find the dry line.',
      mods: StatMods(grip: 2, control: -1),
      pureMods: StatMods(grip: 1),
      traitCommand: 'find_line',
      signatureCommand: 'dry_line',
    ),
    Allele(
      locus: Locus.claw,
      index: 2,
      code: 'h',
      name: 'Hooked',
      blurb: 'Hooks the dirt and pivots on it.',
      mods: StatMods(grip: 1, momentumGain: 1),
      pureMods: StatMods(momentumGain: 1),
      traitCommand: 'hook_turn',
      signatureCommand: 'switchback',
    ),
  ];

  static List<Allele> of(Locus l) => switch (l) {
    Locus.stride => stride,
    Locus.wind => wind,
    Locus.temper => temper,
    Locus.plumage => plumage,
    Locus.comb => comb,
    Locus.claw => claw,
  };

  static Allele at(Locus l, int index) =>
      of(l)[index.clamp(0, of(l).length - 1)];

  /// Every allele in the game, in locus order. Used by the Ledger.
  static List<Allele> get all =>
      Locus.values.expand((l) => of(l)).toList(growable: false);

  /// Baseline stats before any allele modifiers.
  static const StatMods baseline = StatMods(
    stamina: 30,
    stride: 3,
    effort: 3,
    grip: 0,
    control: 1,
    recovery: 4,
    hand: 4,
  );
}
