import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Auto-slices the transparent sprite sheets into individual PNG files.
///
/// Approach:
/// 1. Build an alpha mask (a > threshold).
/// 2. Label 8-connected components.
/// 3. Cluster nearby components into single "items" (handles Zzz, tears,
///    two-lens star glasses, etc.) using bounding-box gap proximity.
/// 4. Arrange items into rows (by vertical overlap) then columns (left->right).
/// 5. Crop each item's bounding box (with padding) and save as PNG.
///
/// Also writes a montage per sheet into `tool/montage` for visual QA.

class Box {
  int minX, minY, maxX, maxY, area;
  Box(this.minX, this.minY, this.maxX, this.maxY, this.area);
  int get w => maxX - minX + 1;
  int get h => maxY - minY + 1;
  double get cx => (minX + maxX) / 2;
  double get cy => (minY + maxY) / 2;
  void merge(Box o) {
    minX = math.min(minX, o.minX);
    minY = math.min(minY, o.minY);
    maxX = math.max(maxX, o.maxX);
    maxY = math.max(maxY, o.maxY);
    area += o.area;
  }
}

List<Box> labelComponents(img.Image im, int alphaT) {
  final w = im.width, h = im.height;
  final parent = List<int>.filled(w * h, -2); // -2 = background
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  void union(int a, int b) {
    final ra = find(a), rb = find(b);
    if (ra != rb) parent[ra] = rb;
  }

  bool fg(int x, int y) => im.getPixel(x, y).a > alphaT;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final idx = y * w + x;
      if (!fg(x, y)) continue;
      parent[idx] = idx;
      // check left, up, up-left, up-right (already-visited neighbours)
      if (x > 0 && fg(x - 1, y)) union(idx, idx - 1);
      if (y > 0 && fg(x, y - 1)) union(idx, idx - w);
      if (x > 0 && y > 0 && fg(x - 1, y - 1)) union(idx, idx - w - 1);
      if (x < w - 1 && y > 0 && fg(x + 1, y - 1)) union(idx, idx - w + 1);
    }
  }

  final boxes = <int, Box>{};
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final idx = y * w + x;
      if (parent[idx] == -2) continue;
      final root = find(idx);
      final b = boxes[root];
      if (b == null) {
        boxes[root] = Box(x, y, x, y, 1);
      } else {
        if (x < b.minX) b.minX = x;
        if (y < b.minY) b.minY = y;
        if (x > b.maxX) b.maxX = x;
        if (y > b.maxY) b.maxY = y;
        b.area++;
      }
    }
  }
  return boxes.values.toList();
}

/// Cluster boxes whose bounding boxes are within [gap] px of each other.
List<Box> cluster(List<Box> boxes, int gap) {
  final items = <Box>[];
  final used = List<bool>.filled(boxes.length, false);
  bool near(Box a, Box b) {
    final dx = math.max(0, math.max(a.minX - b.maxX, b.minX - a.maxX));
    final dy = math.max(0, math.max(a.minY - b.maxY, b.minY - a.maxY));
    return dx <= gap && dy <= gap;
  }

  for (int i = 0; i < boxes.length; i++) {
    if (used[i]) continue;
    final group = Box(boxes[i].minX, boxes[i].minY, boxes[i].maxX,
        boxes[i].maxY, boxes[i].area);
    used[i] = true;
    bool changed = true;
    while (changed) {
      changed = false;
      for (int j = 0; j < boxes.length; j++) {
        if (used[j]) continue;
        if (near(group, boxes[j])) {
          group.merge(boxes[j]);
          used[j] = true;
          changed = true;
        }
      }
    }
    items.add(group);
  }
  return items;
}

/// Order items into a natural reading grid: group by rows using vertical
/// overlap of centers, then sort each row left-to-right.
List<Box> orderGrid(List<Box> items) {
  final sorted = [...items]..sort((a, b) => a.cy.compareTo(b.cy));
  final rows = <List<Box>>[];
  for (final b in sorted) {
    List<Box>? target;
    for (final row in rows) {
      final ref = row.first;
      final rowH = (ref.maxY - ref.minY);
      if ((b.cy - ref.cy).abs() < rowH * 0.6) {
        target = row;
        break;
      }
    }
    if (target == null) {
      rows.add([b]);
    } else {
      target.add(b);
    }
  }
  final result = <Box>[];
  for (final row in rows) {
    row.sort((a, b) => a.cx.compareTo(b.cx));
    result.addAll(row);
  }
  return result;
}

img.Image crop(img.Image src, Box b, int pad) {
  final minX = math.max(0, b.minX - pad);
  final minY = math.max(0, b.minY - pad);
  final maxX = math.min(src.width - 1, b.maxX + pad);
  final maxY = math.min(src.height - 1, b.maxY + pad);
  return img.copyCrop(src,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

/// Attach small fragments (Zzz, tears, sparkles) to the nearest big item.
List<Box> attachSmall(List<Box> boxes, double bigFrac, double noiseFrac) {
  final maxArea = boxes.fold<int>(0, (m, b) => math.max(m, b.area));
  final big = boxes.where((b) => b.area >= maxArea * bigFrac).toList();
  final small = boxes
      .where((b) =>
          b.area < maxArea * bigFrac && b.area >= maxArea * noiseFrac)
      .toList();
  for (final s in small) {
    Box? best;
    double bestD = double.infinity;
    for (final b in big) {
      final dx = math.max(0, math.max(s.minX - b.maxX, b.minX - s.maxX));
      final dy = math.max(0, math.max(s.minY - b.maxY, b.minY - s.maxY));
      final d = dx * dx + dy * dy.toDouble();
      if (d < bestD) {
        bestD = d.toDouble();
        best = b;
      }
    }
    if (best != null) best.merge(s);
  }
  return big;
}

class Sheet {
  final String file;
  final String outName;
  final int alphaT; // alpha threshold to break faint shadow bridges
  final int gap; // clustering gap in px (joins anti-aliased touching parts)
  final double bigFrac; // components >= maxArea*bigFrac are standalone items
  final double noiseFrac; // components below this are discarded
  const Sheet(this.file, this.outName,
      {this.alphaT = 90,
      this.gap = 8,
      this.bigFrac = 0.06,
      this.noiseFrac = 0.004});
}

void main() {
  const gp = 'assets/Nestline_Speedway_gameplay_assets';
  final sheets = <Sheet>[
    Sheet('$gp/chicken_asset.webp', 'chicken', bigFrac: 0.18),
    Sheet('$gp/eggs_asset.webp', 'egg', bigFrac: 0.12),
    Sheet('$gp/foods_asset.webp', 'food', bigFrac: 0.10),
    Sheet('$gp/care_items_asset.webp', 'care', bigFrac: 0.06),
    Sheet('$gp/collectible_rewards_asset.webp', 'reward', bigFrac: 0.05),
    Sheet('$gp/coop_upgrade_asset.webp', 'coop', bigFrac: 0.03,
        noiseFrac: 0.006),
    Sheet('$gp/cute_chicken_toys_asset.webp', 'toy', bigFrac: 0.06),
    Sheet('$gp/decorative_chicken_feathers_asset.webp', 'feather',
        bigFrac: 0.05),
    Sheet('$gp/decorative_farm_plants_asset.webp', 'plant', bigFrac: 0.03,
        noiseFrac: 0.006),
    Sheet('$gp/wearable_accessories_variant2_asset.webp', 'accessory',
        bigFrac: 0.02, noiseFrac: 0.003),
  ];

  final montageDir = Directory('tool/montage')..createSync(recursive: true);

  for (final sheet in sheets) {
    final im = img.decodeWebP(File(sheet.file).readAsBytesSync())!;
    final comps = labelComponents(im, sheet.alphaT);
    var items = cluster(comps, sheet.gap);
    items = attachSmall(items, sheet.bigFrac, sheet.noiseFrac);
    items = orderGrid(items);

    final outDir = Directory('assets/cut/${sheet.outName}')
      ..createSync(recursive: true);
    final crops = <img.Image>[];
    for (int i = 0; i < items.length; i++) {
      final c = crop(im, items[i], 6);
      crops.add(c);
      File('${outDir.path}/${sheet.outName}_$i.png')
          .writeAsBytesSync(img.encodePng(c));
    }

    // montage: single row scaled to 160px tall on gray bg with index labels
    const cell = 170;
    const th = 160;
    final montage = img.Image(width: cell * crops.length, height: cell + 24);
    img.fill(montage, color: img.ColorRgb8(60, 60, 70));
    for (int i = 0; i < crops.length; i++) {
      var c = crops[i];
      final scale = th / math.max(c.width, c.height);
      c = img.copyResize(c,
          width: (c.width * scale).round(),
          height: (c.height * scale).round());
      final dx = i * cell + (cell - c.width) ~/ 2;
      final dy = (cell - c.height) ~/ 2 + 20;
      img.compositeImage(montage, c, dstX: dx, dstY: dy);
      img.drawString(montage, '$i',
          font: img.arial24, x: i * cell + 6, y: 2, color: img.ColorRgb8(255, 230, 90));
    }
    File('${montageDir.path}/${sheet.outName}.png')
        .writeAsBytesSync(img.encodePng(montage));
    stdout.writeln('${sheet.outName}: ${crops.length} items -> '
        'tool/montage/${sheet.outName}.png');
  }
}
