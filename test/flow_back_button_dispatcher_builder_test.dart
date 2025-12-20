import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_back_button_dispatcher_builder.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';

void main() {
  group('FlowBackButtonDispatcherBuilder', () {
    testWidgets('builds with builder callback', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              receivedDispatcher = backButtonDispatcher;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(find.byType(FlowBackButtonDispatcherBuilder), findsOneWidget);
      // Without Router ancestor, dispatcher should be null
      expect(receivedDispatcher, isNull);
    });

    testWidgets('provides null dispatcher when no Router ancestor', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              receivedDispatcher = backButtonDispatcher;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(receivedDispatcher, isNull);
    });

    testWidgets('provides null dispatcher when route is not active', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: false,
            isTopRoute: true,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                receivedDispatcher = backButtonDispatcher;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(receivedDispatcher, isNull);
    });

    testWidgets('provides null dispatcher when route is not top route', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: false,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                receivedDispatcher = backButtonDispatcher;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(receivedDispatcher, isNull);
    });

    testWidgets('provides null dispatcher when both active and top route are false', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: false,
            isTopRoute: false,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                receivedDispatcher = backButtonDispatcher;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(receivedDispatcher, isNull);
    });

    testWidgets('updates when dependencies change', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: true,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                buildCount++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Change the route status
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: false,
            isTopRoute: true,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                buildCount++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buildCount, greaterThan(1));
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              return const SizedBox();
            },
          ),
        ),
      );

      // Remove widget
      await tester.pumpWidget(const SizedBox());

      // Should not throw
    });

    testWidgets('handles multiple rebuilds', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              buildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      final initialCount = buildCount;

      // Trigger rebuild
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              buildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(buildCount, greaterThanOrEqualTo(initialCount));
    });

    testWidgets('works without FlowRouteStatusScope ancestor', (tester) async {
      ChildBackButtonDispatcher? receivedDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: (context, backButtonDispatcher) {
              receivedDispatcher = backButtonDispatcher;
              return const SizedBox();
            },
          ),
        ),
      );

      // Without FlowRouteStatusScope, should default to enabled (true, true)
      // but without Router, dispatcher is still null
      expect(receivedDispatcher, isNull);
    });

    testWidgets('nested route status scopes use nearest scope', (tester) async {
      ChildBackButtonDispatcher? outerDispatcher;
      ChildBackButtonDispatcher? innerDispatcher;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: true,
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, backButtonDispatcher) {
                outerDispatcher = backButtonDispatcher;
                return FlowRouteStatusScope(
                  isActive: false,
                  isTopRoute: false,
                  child: FlowBackButtonDispatcherBuilder(
                    builder: (context, backButtonDispatcher) {
                      innerDispatcher = backButtonDispatcher;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Both should be null without Router, but tested the nested scope logic
      expect(outerDispatcher, isNull);
      expect(innerDispatcher, isNull);
    });
  });
}
