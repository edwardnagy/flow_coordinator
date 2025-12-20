import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';

void main() {
  group('FlowRouteStatusScope', () {
    testWidgets('provides status values to descendants', (tester) async {
      FlowRouteStatusScope? foundScope;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              foundScope = FlowRouteStatusScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(foundScope, isNotNull);
      expect(foundScope!.isActive, isTrue);
      expect(foundScope!.isTopRoute, isTrue);
    });

    testWidgets('maybeOf returns null when no scope exists', (tester) async {
      FlowRouteStatusScope? foundScope;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            foundScope = FlowRouteStatusScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(foundScope, isNull);
    });

    testWidgets('provides inactive status', (tester) async {
      FlowRouteStatusScope? foundScope;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: false,
          isTopRoute: false,
          child: Builder(
            builder: (context) {
              foundScope = FlowRouteStatusScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(foundScope, isNotNull);
      expect(foundScope!.isActive, isFalse);
      expect(foundScope!.isTopRoute, isFalse);
    });

    testWidgets('nested scopes return nearest scope', (tester) async {
      FlowRouteStatusScope? outerFound;
      FlowRouteStatusScope? innerFound;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              outerFound = FlowRouteStatusScope.maybeOf(context);
              return FlowRouteStatusScope(
                isActive: false,
                isTopRoute: false,
                child: Builder(
                  builder: (context) {
                    innerFound = FlowRouteStatusScope.maybeOf(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(outerFound, isNotNull);
      expect(outerFound!.isActive, isTrue);
      expect(outerFound!.isTopRoute, isTrue);

      expect(innerFound, isNotNull);
      expect(innerFound!.isActive, isFalse);
      expect(innerFound!.isTopRoute, isFalse);
      expect(innerFound, isNot(same(outerFound)));
    });

    testWidgets('updateShouldNotify returns true when isActive changes', (tester) async {
      var rebuildCount = 0;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: false,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 2);
    });

    testWidgets('updateShouldNotify returns true when isTopRoute changes', (tester) async {
      var rebuildCount = 0;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: false,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 2);
    });

    testWidgets('updateShouldNotify returns false when values unchanged', (tester) async {
      var rebuildCount = 0;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      // Should not rebuild since values haven't changed
      expect(rebuildCount, 1);
    });
  });
}
