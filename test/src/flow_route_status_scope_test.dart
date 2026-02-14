import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouteStatusScope', () {
    testWidgets('maybeOf returns scope when present', (tester) async {
      FlowRouteStatusScope? result;
      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: false,
          child: Builder(
            builder: (context) {
              result = FlowRouteStatusScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
      expect(result!.isTopRoute, isFalse);
    });

    testWidgets('maybeOf returns null when not present', (tester) async {
      FlowRouteStatusScope? result;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            result = FlowRouteStatusScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(result, isNull);
    });

    test('updateShouldNotify returns false when values are same', () {
      const scope = FlowRouteStatusScope(
        isActive: true,
        isTopRoute: true,
        child: SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          const FlowRouteStatusScope(
            isActive: true,
            isTopRoute: true,
            child: SizedBox(),
          ),
        ),
        isFalse,
      );
    });

    test('updateShouldNotify returns true when isActive differs', () {
      const scope = FlowRouteStatusScope(
        isActive: true,
        isTopRoute: true,
        child: SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          const FlowRouteStatusScope(
            isActive: false,
            isTopRoute: true,
            child: SizedBox(),
          ),
        ),
        isTrue,
      );
    });

    test('updateShouldNotify returns true when isTopRoute differs', () {
      const scope = FlowRouteStatusScope(
        isActive: true,
        isTopRoute: true,
        child: SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          const FlowRouteStatusScope(
            isActive: true,
            isTopRoute: false,
            child: SizedBox(),
          ),
        ),
        isTrue,
      );
    });
  });
}
