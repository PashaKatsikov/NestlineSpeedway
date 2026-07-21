import 'package:flutter_test/flutter_test.dart';

import 'package:nestline_speedway/data/catalog.dart';

void main() {
  test('catalog content is defined', () {
    expect(Catalog.eggs.length, 7);
    expect(Catalog.foods.length, 8);
    expect(Catalog.care.length, 9);
    expect(Catalog.accessories.length, 42);
    expect(Catalog.decor.length, 32);
  });
}
