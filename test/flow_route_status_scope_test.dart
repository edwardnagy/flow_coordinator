import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouteStatusScope', () {
    testWidgets('provides isActive and isTopRoute to descendants',
        (tester) async {
      FlowRouteStatusScope? capturedScope;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: false,
          child: Builder(
            builder: (context) {
              capturedScope = FlowRouteStatusScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedScope, isNotNull);
      expect(capturedScope!.isActive, true);
      expect(capturedScope!.isTopRoute, false);
    });

    testWidgets('maybeOf returns null when not found', (tester) async {
      FlowRouteStatusScope? capturedScope;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedScope = FlowRouteStatusScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(capturedScope, isNull);
    });

    testWidgets('updateShouldNotify returns true when isActive changes',
        (tester) async {
      var notifyCount = 0;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              notifyCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(notifyCount, 1);

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: false,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              notifyCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(notifyCount, 2);
    });

    testWidgets('updateShouldNotify returns true when isTopRoute changes',
        (tester) async {
      var notifyCount = 0;

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: true,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              notifyCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(notifyCount, 1);

      await tester.pumpWidget(
        FlowRouteStatusScope(
          isActive: true,
          isTopRoute: false,
          child: Builder(
            builder: (context) {
              FlowRouteStatusScope.maybeOf(context);
              notifyCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(notifyCount, 2);
    });
  });
}
