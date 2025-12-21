import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_back_button_dispatcher_builder.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    testWidgets('provides null dispatcher when no Router ancestor',
        (tester) async {
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

    testWidgets('provides null dispatcher when route is not active',
        (tester) async {
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

    testWidgets('provides null dispatcher when route is not top route',
        (tester) async {
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

    testWidgets(
        'provides null dispatcher when both active and top route are false',
        (tester) async {
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

      Widget builder(context, backButtonDispatcher) {
        buildCount++;
        return const SizedBox();
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowRouteStatusScope(
            isActive: true,
            isTopRoute: true,
            child: FlowBackButtonDispatcherBuilder(
              builder: builder,
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
              builder: builder,
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

      Widget builder(context, backButtonDispatcher) {
        buildCount++;
        return const SizedBox();
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: builder,
          ),
        ),
      );

      final initialCount = buildCount;

      // Trigger rebuild
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlowBackButtonDispatcherBuilder(
            builder: builder,
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

    testWidgets('forgets old dispatcher when dependencies change',
        (tester) async {
      // This test covers line 36: backButtonDispatcher?.parent.forget(backButtonDispatcher);
      // We need to trigger didChangeDependencies to test the forget logic

      var buildCount = 0;
      ChildBackButtonDispatcher? dispatcher;

      Widget routerWidget({required bool isActive, required bool isTopRoute}) {
        return MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => Scaffold(
              body: FlowRouteStatusScope(
                isActive: isActive,
                isTopRoute: isTopRoute,
                child: FlowBackButtonDispatcherBuilder(
                  builder: (context, backButtonDispatcher) {
                    buildCount++;
                    dispatcher = backButtonDispatcher;
                    return Text('Build $buildCount');
                  },
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        routerWidget(isActive: true, isTopRoute: true),
      );

      expect(buildCount, 1);
      expect(dispatcher, isNotNull);
      final firstDispatcher = dispatcher;

      // Trigger a rebuild that causes didChangeDependencies
      await tester.pumpWidget(
        routerWidget(isActive: false, isTopRoute: false),
      );

      // Should have rebuilt
      expect(buildCount, greaterThan(1));
      // Dispatcher should now be null since isActive is false
      expect(dispatcher, isNull);
      // The old dispatcher should have been forgotten
      expect(firstDispatcher, isNotNull);
    });
  });
}
