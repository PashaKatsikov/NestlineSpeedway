/// A first-visit walkthrough.
///
/// Screens ask the game whether their lesson is still owed and mark it done once
/// the player has been shown it, so the coach marks appear exactly once per save
/// and can all be re-armed together from Settings.
enum Guide {
  /// The hub: the season panel, the egg bank and the four rooms.
  stable,

  /// The branching schedule and the bird waiting at the line.
  schedule,

  /// The race HUD: terrain, lanes, stamina and the hand.
  race,

  /// Pairing two birds and reading the forecast.
  hatchery,
}
