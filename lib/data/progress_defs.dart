// Definitions for achievements and daily-quest templates. Both are evaluated
// against integer counters tracked in GameState.

class Achievement {
  final String id;
  final String name;
  final String desc;
  final String metric; // key in GameState.counters
  final int goal;
  final int reward; // coins
  final int badge; // reward sprite index
  const Achievement(this.id, this.name, this.desc, this.metric, this.goal,
      this.reward, this.badge);
}

class QuestTemplate {
  final String id;
  final String name;
  final String metric; // key in GameState per-day counters
  final int goal;
  final int coinReward;
  final int xpReward;
  const QuestTemplate(
      this.id, this.name, this.metric, this.goal, this.coinReward, this.xpReward);
}

class ProgressDefs {
  ProgressDefs._();

  static const List<Achievement> achievements = [
    Achievement('a_firstegg', 'First Feather', 'Collect your first egg',
        'eggsCollected', 1, 40, 12),
    Achievement('a_eggs50', 'Egg Enthusiast', 'Collect 50 eggs',
        'eggsCollected', 50, 150, 12),
    Achievement('a_eggs250', 'Nest Master', 'Collect 250 eggs',
        'eggsCollected', 250, 500, 13),
    Achievement('a_feed25', 'Chef', 'Feed the chicken 25 times', 'fed', 25,
        120, 14),
    Achievement('a_feed100', 'Master Chef', 'Feed the chicken 100 times',
        'fed', 100, 400, 14),
    Achievement('a_pet50', 'Best Friend', 'Pet your chicken 50 times', 'pet',
        50, 160, 15),
    Achievement('a_bath30', 'Squeaky Clean', 'Give 30 baths', 'bathed', 30,
        180, 15),
    Achievement('a_sell100', 'Egg Trader', 'Sell 100 eggs', 'eggsSold', 100,
        350, 16),
    Achievement('a_legendary', 'Lucky Cluck', 'Find a Legendary egg',
        'legendaryEggs', 1, 500, 17),
    Achievement('a_coins5k', 'Coin Collector', 'Earn 5,000 coins total',
        'coinsEarned', 5000, 300, 13),
    Achievement('a_coins25k', 'Golden Tycoon', 'Earn 25,000 coins total',
        'coinsEarned', 25000, 900, 17),
    Achievement('a_level5', 'Growing Up', 'Reach level 5', 'level', 5, 150,
        12),
    Achievement('a_level15', 'Seasoned Keeper', 'Reach level 15', 'level', 15,
        450, 13),
    Achievement('a_level30', 'Legendary Keeper', 'Reach level 30', 'level', 30,
        1200, 17),
    Achievement('a_acc10', 'Fashionista', 'Own 10 accessories',
        'accessoriesOwned', 10, 300, 16),
    Achievement('a_coop15', 'Home Improver', 'Own 15 coop items',
        'coopOwned', 15, 350, 14),
    Achievement('a_skins5', 'Plume Palette', 'Own 5 feather skins',
        'skinsOwned', 5, 280, 15),
    Achievement('a_games25', 'Playful Spirit', 'Play 25 mini-games',
        'gamesPlayed', 25, 260, 16),
    Achievement('a_bg3', 'Wanderer', 'Unlock 3 coop backgrounds',
        'bgUnlocked', 3, 320, 13),
    Achievement('a_quests20', 'Task Hero', 'Complete 20 daily quests',
        'questsDone', 20, 400, 17),
  ];

  /// Rotating daily-quest pool. Three are chosen per day.
  static const List<QuestTemplate> questPool = [
    QuestTemplate('q_feed', 'Feed the chicken 5 times', 'fed', 5, 60, 20),
    QuestTemplate('q_pet', 'Pet your chicken 4 times', 'pet', 4, 50, 15),
    QuestTemplate('q_bath', 'Give 2 baths', 'bathed', 2, 55, 18),
    QuestTemplate('q_collect', 'Collect 8 eggs', 'eggsCollected', 8, 80, 25),
    QuestTemplate('q_sell', 'Sell 6 eggs', 'eggsSold', 6, 70, 22),
    QuestTemplate('q_games', 'Play 2 mini-games', 'gamesPlayed', 2, 90, 30),
    QuestTemplate('q_toy', 'Play with a toy 3 times', 'toyPlayed', 3, 60, 20),
    QuestTemplate('q_coins', 'Earn 200 coins', 'coinsEarnedToday', 200, 80, 24),
    QuestTemplate('q_groom', 'Groom the chicken 3 times', 'groomed', 3, 55, 18),
  ];
}
