import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/campaign/meets.dart';
import 'package:nestline_circuit/campaign/kit.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

class MerchantScreen extends StatelessWidget {
  const MerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final season = game.season;
    final stock = game.traderStock;

    if (season == null || stock == null) {
      return const Scaffold(body: VacantNote('The trader has moved on.'));
    }

    return Stage(
      title: 'Trader',
      subtitle: 'Grain buys tack, feed and answers. Nothing here restocks.',
      plate: Backdrops.scene(2),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatMark(
          label: 'grain',
          value: '${season.grain}',
          iconAsset: Atlas.grain,
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
              itemBuilder: (context, i) => _StallCard(
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
                  style: Face.text(11),
                ),
              ),
              LeadButton(
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

class _StallCard extends StatelessWidget {
  const _StallCard({
    required this.line,
    required this.affordable,
    required this.onBuy,
  });

  final StallLine line;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final icon = switch (line.kind) {
      StallKind.tack => Tack.byId(line.tackId ?? '')?.iconPath,
      StallKind.consumable => Consumable.byId(
        line.consumableId ?? '',
      )?.iconPath,
      StallKind.geneRead => Atlas.plume(2),
    };

    return Pane(
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
                        style: Face.title(13),
                      ),
                      if (blurbLines > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          line.blurb,
                          maxLines: blurbLines,
                          overflow: TextOverflow.ellipsis,
                          style: Face.text(10),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Image.asset(Atlas.grain, width: 15),
                          const SizedBox(width: 4),
                          Text(
                            line.sold ? 'sold' : '${line.price}',
                            style: Face.number(
                              12,
                              color: line.sold
                                  ? Pigment.inkMute
                                  : affordable
                                  ? Pigment.amber
                                  : Pigment.bad,
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
