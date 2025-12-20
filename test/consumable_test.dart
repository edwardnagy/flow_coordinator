import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/consumable.dart';

void main() {
  group('Consumable', () {
    test('creates consumable with value', () {
      final consumable = Consumable(42);
      expect(consumable, isNotNull);
    });

    test('consumeOrNull returns value on first call', () {
      final consumable = Consumable('test value');
      final result = consumable.consumeOrNull();
      expect(result, equals('test value'));
    });

    test('consumeOrNull returns null on second call', () {
      final consumable = Consumable('test value');
      consumable.consumeOrNull(); // First call
      final result = consumable.consumeOrNull(); // Second call
      expect(result, isNull);
    });

    test('creates consumable with isConsumed = true', () {
      final consumable = Consumable('test', isConsumed: true);
      final result = consumable.consumeOrNull();
      expect(result, isNull);
    });

    test('creates consumable with isConsumed = false (default)', () {
      final consumable = Consumable('test', isConsumed: false);
      final result = consumable.consumeOrNull();
      expect(result, equals('test'));
    });

    test('works with different types', () {
      final stringConsumable = Consumable('string');
      expect(stringConsumable.consumeOrNull(), equals('string'));

      final intConsumable = Consumable(123);
      expect(intConsumable.consumeOrNull(), equals(123));

      final listConsumable = Consumable([1, 2, 3]);
      expect(listConsumable.consumeOrNull(), equals([1, 2, 3]));

      final mapConsumable = Consumable({'key': 'value'});
      expect(mapConsumable.consumeOrNull(), equals({'key': 'value'}));
    });

    test('multiple consecutive calls return null after first consumption', () {
      final consumable = Consumable('value');
      expect(consumable.consumeOrNull(), equals('value'));
      expect(consumable.consumeOrNull(), isNull);
      expect(consumable.consumeOrNull(), isNull);
      expect(consumable.consumeOrNull(), isNull);
    });
  });
}
