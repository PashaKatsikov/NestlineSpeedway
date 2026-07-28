# Nestline Speedway — Game Design Document

**Genre:** tactical racing roguelike with a genetics-driven command deck  
**Platform:** iOS / Android (Flutter), landscape  
**Session length:** 4–7 minutes per race, 30–45 minutes per season  
**Monetisation:** none. No ads, no IAP, no analytics, no network gameplay.

---

## 1. What the game is

Nestline Speedway is a racing game where you never steer.

You are the head of a racing stable. Your birds run the Nestline circuit, and a
race is not a reflex test — it is a tactical duel over stamina, positioning and
timing, resolved segment by segment. Each turn you see the track ahead, you see
what every rival intends to do, and you spend Effort playing command cards:
surge, draft behind a leader to save wind, cut inside on the corner, flap over
the hay bales, hold the line to deny an overtake.

The twist that makes it not a card game with a racing skin: **your command deck
is your bird's genome.** You do not draft cards from a reward screen. You breed
them. Each hen contributes cards determined by her alleles at six loci, so
improving your deck means running a real Mendelian breeding programme across
generations — and the strongest commands sit behind recessive alleles that only
express when homozygous, which means carrying them silently through a pedigree
and paying the inbreeding cost when you finally pair two carriers.

So the loop is: **race the circuit → win eggs and purses → breed toward a genome
you designed → race a harder circuit with the deck that genome produces.**

## 2. Structure

```
STABLE (persistent)                SEASON (roguelike run)
┌────────────────────────┐         ┌───────────────────────────────────┐
│ Flock roster           │         │ Branching schedule, 12–15 events  │
│ Hatchery (breeding)    │ ──────► │ Sprint / Endurance / Steeplechase │
│ Stable upgrades        │  enter  │ Rival Duel / Training / Trader    │
│ Codex                  │ ◄────── │ Rest / Grand Prix finale          │
└────────────────────────┘ eggs +  └───────────────────────────────────┘
                           purse        injuries carry home
```

A **season** is one run. You enter with one racer plus two stablemates in
reserve, walk a branching schedule of events across the eight Nestline venues,
and finish at the Grand Prix. Placement in each event pays a purse and eggs.
Injuries accumulate on the bird and follow her back to the stable; a severe
injury ends her career permanently. The stable, the pedigree and every allele
you have discovered are persistent.

## 3. The race

A race is a sequence of **segments**. The field runs in **three lanes**. Each
racer has Position (segment + progress within it), Stamina, Momentum and
statuses. Turn order within a segment is by track position, leader first.

**One turn:**

1. **Read the track.** The next two segments are visible with their terrain.
2. **Read intents.** Every rival telegraphs their command for this turn.
3. **Spend Effort** (base 3, modified by the Comb locus and tack) to play cards
   from a hand of 5 drawn from your bird's genome deck.
4. **Resolve** your commands, then rivals' in position order.
5. **Apply terrain** for the segment each racer now occupies.

**Resources**

- **Stamina** is the real currency of a race. Surging costs it, drafting refunds
  it, Steady recovers it. At zero the bird is **Blown**: distance gained is
  halved and Effort drops by one until she recovers.
- **Momentum** carries speed between turns — it adds free distance, but corners
  convert excess Momentum into Stamina loss unless the bird has grip or plays a
  balancing command. Building a big lead into a corner is a mistake, and that
  single rule is what gives the race its rhythm.

**Terrain** (per segment): Straight, Corner, Mud, Puddle, Hay Bales, Gravel,
Downhill, Crowd Stretch. Each changes what cards are worth doing — Draft is
strong on a Straight and useless in Mud; Hay Bales punish anyone without Flap;
Gravel rewards a Fine claw.

**Drafting** is the tactical spine: if you end a turn directly behind a racer in
the same lane you pay a third less Stamina to move. So the optimal line is
usually *not* the front — you want to sit second until the last corner, which
means the AI leaders are working for you, and the moment to break away is the
central decision of every race.

**Cards** come in four kinds: Move (distance), Guard (deny/absorb), Skill
(utility, lane, stamina) and Form (persistent buffs for the rest of the race).
Statuses: Ruffled, Exposed, Frenzy, Composure, Winded, Clipped, Dazed, Second
Wind.

## 4. Genetics

Six loci, diploid, Mendelian inheritance with a 2% per-allele mutation rate.

| Locus | Alleles (dominant → recessive) | Governs |
|---|---|---|
| **Stride** | Long > Short > Bounding | Distance per Move command |
| **Wind** | Deep > Even > Shallow | Stamina pool and recovery |
| **Temper** | Steady > Eager > Wild | Momentum control, risk commands |
| **Plumage** | Speckled > Gold > White > Rainbow | Command school and silks |
| **Comb** | Single > Rose > Crown | Effort per turn |
| **Claw** | Broad > Fine > Hooked | Terrain grip, lane changes |

**Expression.** Homozygous recessive is a *pure trait*: it unlocks that locus's
signature command and its strongest stat modifier. Heterozygous shows the
dominant phenotype but makes the bird a **carrier**. Two pure traits on one bird
produce a **Synergy** command — there are 15 documented pairs.

**Inbreeding.** Each bird carries an inbreeding coefficient F from a
five-generation pedigree. At F ≥ 0.25 she is *Frail* (−20% stamina pool); at
F ≥ 0.375 she also gets *Weak Hatch* (one fewer command contributed). Line
breeding is the fast route to pure traits and the fast route to a ruined stable,
so fresh blood from Trader stock and Event prizes is a resource in itself.

**Discovery.** Genotypes are hidden. You see phenotype until the Codex records
an allele, either by hatching a homozygote or by buying a Gene Read from a
Trader. Early seasons are genuinely about deducing what your line carries.

## 5. Economy

| Resource | Earned from | Spent on |
|---|---|---|
| **Grain** | Race purses, events | Trader: tack, feed, gene reads, entries |
| **Eggs** (7 tiers) | Placements, Grand Prix | Breeding pairs in the Hatchery |
| **Tack** | Rival Duels, Trader | 42 pieces of persistent race gear |
| **Feed** | Trader, rewards | 8 pre-race consumables |
| **Remedies** | Rest nodes | 9 injury and status treatments |
| **Supplements** | Events | 32 herbal one-shot effects |

Eggs are the bridge between the season and the stable: they are the only way to
breed, and higher tiers widen the allele pool and cut mutation noise. This is why
you keep pushing a hurt bird one event further.

## 6. Venues

The eight Nestline venues, each with its own segment profile:

1. **Frostpine Loop** — long corners, gravel, cold drains stamina
2. **Barnyard Bowl** — short and tight, constant lane fighting
3. **Sunhill Sprint** — pure straights, drafting duel
4. **Meadowgate Mile** — balanced, the tutorial venue
5. **Goldfield Straight** — the longest run, endurance test
6. **Autumn Ridge** — downhill momentum traps
7. **Blossom Vale Circuit** — crowd stretches, mud after rain
8. **Midnight Oval** — the Grand Prix, every terrain, three laps

## 7. Rivals

Rivals are named birds with archetypes that read clearly from their intents:
**Frontrunner** (leads, fades), **Closer** (drafts, then kicks), **Pacer**
(never blown), **Bruiser** (blocks and clips), **Technician** (perfect corners).
Three **Champions** headline the Grand Prix with multi-phase behaviour and a
signature command of their own.

## 8. Meta progression

- **Stable upgrades** (33): permanent — Incubator (+1 hatch slot), Feed Silo
  (start with grain), Paddock (+1 reserve racer), Gene Lab (reveal one allele
  per hatch), Track Wall (reduce injury severity).
- **Codex**: alleles, commands, rivals, synergies, venues. Completion is the
  long game.
- **Higher Grades**: after the first Grand Prix win, ten ascending grades each
  add a permanent circuit modifier.

## 9. Failure

A season ends if your last available racer is retired by injury or you finish
the Grand Prix. Retirement is permanent for that bird. If the stable drops below
two breeding-capable birds, Nestline grants a *claim clutch* of three low-grade
hens so the player is never hard-locked — but a bred pedigree, once lost, is
gone, and that is the real cost of a bad season.

## 10. Relationship to the previous build

The previous submission carried this name but was a chicken care tamagotchi:
tap to pet, wait for eggs, sell eggs, buy hats, three filler mini-games, ten
shop grids, no failure state and no decision the player could get wrong. The
title had nothing to do with the content, which is the core of the 4.3 problem.

This build keeps the art and the name and replaces everything else. Nestline
Speedway is now literally a speedway: a racing circuit with a tactical race
engine, a stamina-and-drafting model, telegraphed rival behaviour, terrain that
changes card value, permanent injury stakes, and a Mendelian breeding programme
that produces the player's deck. Every screen exists to serve a race or the
breeding that feeds it.
