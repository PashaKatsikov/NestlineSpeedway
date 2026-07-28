# Nestline Speedway

A turn-based racing roguelike where you never steer. You breed the racer, and its genome
*is* the deck of commands you get to play once the gate opens. Flutter, offline, no ads, no
purchases, no network.

The design doc in [`docs/DESIGN.md`](docs/DESIGN.md) is the source of truth for mechanics and
balance numbers; this file only covers the code.

## The loop in one paragraph

Six genetic loci decide a bird's stats and, more importantly, which commands appear in its
deck. A race is a sequence of terrain segments across four lanes: you spend effort each turn
to play move, guard, skill and form cards, manage stamina and momentum, and read the intent
each rival telegraphs for next turn. Winning pays grain and eggs; eggs buy hatches, and each
hatch is a Mendelian roll you can stack in your favour by pairing carriers. Push a line too
hard and inbreeding starts costing you stamina and hatch rates, so you cross in outside stock
from traders. A season is a branching map of races and events; losing the finale ends the run,
but the codex, stable upgrades and pedigree persist.

## Layout

| Path | What lives there |
| --- | --- |
| `lib/core/` | Palette, typography, theme, sprite registry, seeded RNG, SFX ids |
| `lib/genetics/` | Loci and alleles, diploid genome, meiosis, pedigree and inbreeding, `Racer`, hatchery |
| `lib/race/` | Track and terrain, entrants, statuses, commands and library, rival AI, `RaceEngine` |
| `lib/season/` | Season map generation, tack and consumables, trader/training encounters, run state |
| `lib/meta/` | Persistent `Stable`, codex, stable upgrades, `SaveService` |
| `lib/state/game.dart` | The single `ChangeNotifier` that drives every screen |
| `lib/ui/` | `widgets/` for the kit, `screens/` for each destination |
| `tool/` | One-off Dart scripts used to slice the source sprite sheets; not shipped |

Two rules keep the dependency graph clean: game logic never imports anything from `lib/ui/`,
and commands talk to the simulation through the `RaceApi` interface in `lib/race/command.dart`
rather than importing `RaceEngine` directly.

## Running it

```bash
flutter pub get
flutter run
```

The app is landscape-only. `flutter test` covers the genetics and the race engine — inheritance
ratios, inbreeding coefficients, drafting, terrain costs, effort limits, and the guarantee that
every archetype produces a legal intent and every race terminates.

```bash
flutter test
flutter analyze
```

## Assets

Shipped art is pre-sliced into `assets/gen/<category>/`. The source sheets live in
`tool/sheets/` and are deliberately excluded from `pubspec.yaml`, so they add nothing to the
bundle. To re-cut a sheet, edit the coordinates in `tool/slice.dart` and run it with `dart run`.

## Save data

`SaveService` writes one versioned JSON blob through `shared_preferences`. It stays on the
device, is never uploaded, and can be wiped from Settings. When you change the shape of
anything persisted, bump `SaveService.schemaVersion` and handle the older version on load — an
unreadable save is discarded rather than crashing the app.
