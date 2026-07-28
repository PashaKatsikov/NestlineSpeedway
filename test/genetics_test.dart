import 'package:flutter_test/flutter_test.dart';
import 'package:nestline_speedway/core/rng.dart';
import 'package:nestline_speedway/genetics/genome.dart';
import 'package:nestline_speedway/genetics/hatchery.dart';
import 'package:nestline_speedway/genetics/locus.dart';
import 'package:nestline_speedway/genetics/pedigree.dart';
import 'package:nestline_speedway/genetics/racer.dart';

Genome genomeWith(Map<Locus, List<int>> pairs) {
  final alleles = List<int>.filled(Locus.values.length * 2, 0);
  for (final entry in pairs.entries) {
    alleles[entry.key.index * 2] = entry.value[0];
    alleles[entry.key.index * 2 + 1] = entry.value[1];
  }
  return Genome(alleles);
}

void main() {
  group('dominance', () {
    test('the lower allele index is the expressed one', () {
      final g = genomeWith({
        Locus.stride: [2, 0],
      });
      expect(g.expressedIndex(Locus.stride), 0);
      expect(g.expressed(Locus.stride).name, 'Long');
    });

    test('a heterozygote is a carrier and reports its hidden allele', () {
      final g = genomeWith({
        Locus.wind: [0, 2],
      });
      expect(g.isHomozygous(Locus.wind), isFalse);
      expect(g.isCarrier(Locus.wind), isTrue);
      expect(g.hidden(Locus.wind)!.name, 'Shallow');
    });

    test('a homozygote hides nothing', () {
      final g = genomeWith({
        Locus.comb: [2, 2],
      });
      expect(g.isHomozygous(Locus.comb), isTrue);
      expect(g.hidden(Locus.comb), isNull);
      expect(g.pureLoci, contains(Locus.comb));
    });

    test('notation writes the dominant allele first', () {
      final g = genomeWith({
        Locus.stride: [2, 0],
      });
      expect(g.notation.split(' ').first, 'Lb');
    });
  });

  group('phenotype', () {
    test('a pure locus grants its signature command as well as the trait', () {
      final pure = Phenotype.of(
        genomeWith({
          Locus.stride: [0, 0],
        }),
      );
      expect(pure.commandIds, contains('stretch_out'));
      expect(pure.commandIds, contains('ground_eater'));
    });

    test('a carrier gets the trait command but not the signature', () {
      final carrier = Phenotype.of(
        genomeWith({
          Locus.stride: [0, 2],
        }),
      );
      expect(carrier.commandIds, contains('stretch_out'));
      expect(carrier.commandIds, isNot(contains('ground_eater')));
    });

    test('pure recessive stride beats pure dominant on ground covered', () {
      // Bounding is worth less on its own but stacks momentum instead.
      final long = Phenotype.of(
        genomeWith({
          Locus.stride: [0, 0],
        }),
      );
      final bounding = Phenotype.of(
        genomeWith({
          Locus.stride: [2, 2],
        }),
      );
      expect(long.stride, greaterThan(bounding.stride));
      expect(bounding.momentumGain, greaterThan(long.momentumGain));
    });

    test('a matching pair of pure traits unlocks a synergy command', () {
      final g = genomeWith({
        Locus.stride: [2, 2],
        Locus.temper: [2, 2],
      });
      final pheno = Phenotype.of(g);
      expect(pheno.synergies.map((s) => s.command), contains('thunder_hop'));
      expect(pheno.commandIds, contains('thunder_hop'));
    });

    test('every allele in the tables has a resolvable pair of commands', () {
      for (final l in Locus.values) {
        for (final allele in l.alleles) {
          final pheno = Phenotype.of(
            genomeWith({
              l: [allele.index, allele.index],
            }),
          );
          expect(pheno.commandIds, contains(allele.traitCommand));
          expect(pheno.commandIds, contains(allele.signatureCommand));
        }
      }
    });
  });

  group('inheritance', () {
    test('two pure parents breed true when mutation is off', () {
      final rng = Rng(7);
      final sire = genomeWith({
        for (final l in Locus.values) l: [0, 0],
      });
      final dam = genomeWith({
        for (final l in Locus.values) l: [0, 0],
      });
      for (var i = 0; i < 50; i++) {
        final chick = Genome.breed(sire, dam, rng, mutation: 0);
        for (final l in Locus.values) {
          expect(chick.first(l), 0);
          expect(chick.second(l), 0);
        }
      }
    });

    test('two carriers produce a recessive homozygote about a quarter of the '
        'time', () {
      final rng = Rng(99);
      final sire = genomeWith({
        Locus.wind: [0, 2],
      });
      final dam = genomeWith({
        Locus.wind: [0, 2],
      });
      var pure = 0;
      const runs = 4000;
      for (var i = 0; i < runs; i++) {
        final chick = Genome.breed(sire, dam, rng, mutation: 0);
        if (chick.first(Locus.wind) == 2 && chick.second(Locus.wind) == 2) {
          pure++;
        }
      }
      expect(pure / runs, closeTo(0.25, 0.03));
    });

    test('a dominant homozygote crossed with a recessive one yields all '
        'carriers', () {
      final rng = Rng(3);
      final sire = genomeWith({
        Locus.claw: [0, 0],
      });
      final dam = genomeWith({
        Locus.claw: [2, 2],
      });
      for (var i = 0; i < 40; i++) {
        final chick = Genome.breed(sire, dam, rng, mutation: 0);
        expect(chick.isHomozygous(Locus.claw), isFalse);
        expect(chick.expressedIndex(Locus.claw), 0);
      }
    });
  });

  group('forecast', () {
    test('the pure chance of two carriers at one locus is one half', () {
      final pedigree = Pedigree();
      final sire = Racer(
        id: 'a',
        name: 'A',
        genome: genomeWith({
          Locus.wind: [0, 2],
        }),
        birthOrder: pedigree.nextBirthOrder,
      );
      final dam = Racer(
        id: 'b',
        name: 'B',
        genome: genomeWith({
          Locus.wind: [0, 2],
        }),
        birthOrder: pedigree.nextBirthOrder,
      );
      // Two of the four gamete combinations match: 0/0 and 2/2.
      expect(Hatchery.pureChance(sire, dam, Locus.wind), 0.5);
    });

    test('forecast probabilities sum to one at every locus', () {
      final rng = Rng(11);
      final pedigree = Pedigree();
      final sire = Hatchery.wildStock(rng, pedigree, grade: 0);
      final dam = Hatchery.wildStock(
        rng,
        pedigree,
        grade: 2,
        taken: [sire.name],
      );
      final forecast = Hatchery.forecast(sire, dam);
      for (final l in Locus.values) {
        final total = forecast[l]!.values.fold<double>(0, (a, b) => a + b);
        expect(total, closeTo(1.0, 1e-9));
      }
    });
  });

  group('pedigree', () {
    test('founders are not inbred', () {
      final pedigree = Pedigree();
      final founders = Hatchery.founders(Rng(5), pedigree);
      expect(founders.length, 3);
      for (final f in founders) {
        expect(pedigree.inbreedingOf(f.sireId, f.damId), 0);
      }
    });

    test('a full-sibling mating gives F = 0.25', () {
      final pedigree = Pedigree();
      final rng = Rng(21);
      final founders = Hatchery.founders(rng, pedigree);
      final sire = founders[0];
      final dam = founders[1];

      final sibA = Hatchery.breed(
        sire: sire,
        dam: dam,
        tier: EggTier.at(0),
        rng: rng,
        pedigree: pedigree,
      );
      final sibB = Hatchery.breed(
        sire: sire,
        dam: dam,
        tier: EggTier.at(0),
        rng: rng,
        pedigree: pedigree,
        taken: [sibA.name],
      );

      expect(sibA.inbreeding, 0);
      expect(pedigree.inbreedingOf(sibA.id, sibB.id), closeTo(0.25, 1e-9));
    });

    test('a parent bred back to its own offspring gives F = 0.25', () {
      final pedigree = Pedigree();
      final rng = Rng(33);
      final founders = Hatchery.founders(rng, pedigree);
      final chick = Hatchery.breed(
        sire: founders[0],
        dam: founders[1],
        tier: EggTier.at(0),
        rng: rng,
        pedigree: pedigree,
      );
      expect(
        pedigree.inbreedingOf(founders[0].id, chick.id),
        closeTo(0.25, 1e-9),
      );
    });

    test('unrelated outside stock brings the coefficient back to zero', () {
      final pedigree = Pedigree();
      final rng = Rng(44);
      final founders = Hatchery.founders(rng, pedigree);
      final chick = Hatchery.breed(
        sire: founders[0],
        dam: founders[1],
        tier: EggTier.at(0),
        rng: rng,
        pedigree: pedigree,
      );
      final outsider = Hatchery.wildStock(rng, pedigree, grade: 1);
      expect(pedigree.inbreedingOf(chick.id, outsider.id), 0);
    });

    test('inbreeding penalties apply at the documented thresholds', () {
      expect(InbreedingPenalty.forCoefficient(0.2).label, '');
      expect(InbreedingPenalty.forCoefficient(0.25).label, 'Frail');
      expect(InbreedingPenalty.forCoefficient(0.4).commandLoss, 1);
    });

    test('a frail bird loses stamina but keeps her commands', () {
      final base = Racer(
        id: 'x',
        name: 'X',
        genome: genomeWith({
          for (final l in Locus.values) l: [0, 0],
        }),
        birthOrder: 1,
      );
      final frail = Racer(
        id: 'y',
        name: 'Y',
        genome: genomeWith({
          for (final l in Locus.values) l: [0, 0],
        }),
        birthOrder: 2,
        inbreeding: 0.26,
      );
      expect(
        frail.phenotype().staminaMax,
        lessThan(base.phenotype().staminaMax),
      );
      expect(
        frail.phenotype().commandIds.length,
        base.phenotype().commandIds.length,
      );
    });
  });

  group('condition', () {
    test('fatigue eats into the stamina a bird brings to the line', () {
      final racer = Racer(
        id: 'f',
        name: 'F',
        genome: Genome.random(Rng(2)),
        birthOrder: 1,
      );
      final fresh = racer.phenotype().staminaMax;
      racer.fatigue = 80;
      expect(racer.phenotype().staminaMax, lessThan(fresh));
    });

    test('a career-ending injury retires a bird', () {
      final racer = Racer(
        id: 'g',
        name: 'G',
        genome: Genome.random(Rng(4)),
        birthOrder: 1,
        injuries: ['tendon'],
      );
      expect(racer.careerOver, isTrue);
    });

    test('rank raises the stat block', () {
      final racer = Racer(
        id: 'h',
        name: 'H',
        genome: Genome.random(Rng(6)),
        birthOrder: 1,
      );
      final base = racer.phenotype().staminaMax;
      racer.xp = 700;
      expect(racer.rank, 5);
      expect(racer.phenotype().staminaMax, greaterThan(base));
    });
  });
}
