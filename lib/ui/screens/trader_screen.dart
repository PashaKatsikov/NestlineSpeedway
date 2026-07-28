import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../season/encounters.dart';
import '../../season/items.dart';
import '../../state/game.dart';
import '../widgets/ui_kit.dart';

class TraderScreen extends StatelessWidget {
  const TraderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final season = game.season;
    final stock = game.traderStock;

    if (season == null || stock == null) {
      return const Scaffold(body: EmptyNote('The trader has moved on.'));
    }

    return GameScreen(
      title: 'Trader',
      subtitle: 'Grain buys tack, feed and answers. Nothing here restocks.',
      plate: Plates.scene(2),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatChip(
          label: 'grain',
          value: '${season.grain}',
          iconAsset: Sprites.grain,
          compact: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 92,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
              ),
              itemCount: stock.length,
              itemBuilder: (context, i) => _StockCard(
                line: stock[i],
                affordable: season.grain >= stock[i].price,
                onBuy: () => game.buy(stock[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fit tack from the schedule screen before your next event.',
                  style: Type.text(11),
                ),
              ),
              PrimaryButton(
                label: 'Back to the schedule',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  season.resolvePending();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.line,
    required this.affordable,
    required this.onBuy,
  });

  final StockLine line;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final icon = switch (line.kind) {
      StockKind.tack => Tack.byId(line.tackId ?? '')?.iconPath,
      StockKind.consumable => Consumable.byId(
        line.consumableId ?? '',
      )?.iconPath,
      StockKind.geneRead => Sprites.plume(2),
    };

    return Panel(
      onTap: line.sold || !affordable ? null : onBuy,
      selected: !line.sold && affordable,
      padding: const EdgeInsets.all(10),
      child: Opacity(
        opacity: line.sold ? 0.4 : 1,
        child: Row(
          children: [
            if (icon != null) Image.asset(icon, width: 38, height: 38),
            const SizedBox(width: 9),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Title and price are the parts you buy on; the description is
                  // what gets trimmed when the grid cell is short.
                  final forBlurb = box.maxHeight - 41;
                  final blurbLines = (forBlurb / 13).floor().clamp(0, 2);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.title(13),
                      ),
                      if (blurbLines > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          line.blurb,
                          maxLines: blurbLines,
                          overflow: TextOverflow.ellipsis,
                          style: Type.text(10),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Image.asset(Sprites.grain, width: 15),
                          const SizedBox(width: 4),
                          Text(
                            line.sold ? 'sold' : '${line.price}',
                            style: Type.number(
                              12,
                              color: line.sold
                                  ? Palette.inkMute
                                  : affordable
                                  ? Palette.amber
                                  : Palette.bad,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
