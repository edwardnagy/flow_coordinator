import 'package:flow_coordinator/src/consumable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Consumable', () {
    test('consumeOrNull returns value on first call', () {
      final consumable = Consumable(42);
      expect(consumable.consumeOrNull(), 42);
    });

    test('consumeOrNull returns null on second call', () {
      final consumable = Consumable(42);
      consumable.consumeOrNull();
      expect(consumable.consumeOrNull(), isNull);
    });

    test(
      'consumeOrNull returns null when created as already consumed',
      () {
        final consumable = Consumable(42, isConsumed: true);
        expect(consumable.consumeOrNull(), isNull);
      },
    );
  });
}
