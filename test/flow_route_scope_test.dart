import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_coordinator_mixin_test.dart';

void main() {
  group('RouteInformation.matchesUrlPattern', () {
    test('matches when path segments are prefix', () {
      final route =
          RouteInformation(uri: Uri(pathSegments: ['home', 'books', '123']));
      final pattern = RouteInformation(uri: Uri(pathSegments: ['home']));

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('matches when path segments match exactly', () {
      final route = RouteInformation(uri: Uri(pathSegments: ['home', 'books']));
      final pattern =
          RouteInformation(uri: Uri(pathSegments: ['home', 'books']));

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when pattern has more segments', () {
      final route = RouteInformation(uri: Uri(pathSegments: ['home']));
      final pattern =
          RouteInformation(uri: Uri(pathSegments: ['home', 'books']));

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('does not match when path segments differ', () {
      final route =
          RouteInformation(uri: Uri(pathSegments: ['home', 'settings']));
      final pattern =
          RouteInformation(uri: Uri(pathSegments: ['home', 'books']));

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('matches when query parameters present in pattern exist in route', () {
      final route = RouteInformation(
        uri: Uri(
          queryParameters: {'tab': 'books', 'filter': 'all', 'page': '1'},
        ),
      );
      final pattern = RouteInformation(
        uri: Uri(queryParameters: {'tab': 'books'}),
      );

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when query parameter value differs', () {
      final route = RouteInformation(
        uri: Uri(queryParameters: {'tab': 'books'}),
      );
      final pattern = RouteInformation(
        uri: Uri(queryParameters: {'tab': 'settings'}),
      );

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('does not match when required query parameter missing', () {
      final route = RouteInformation(
        uri: Uri(queryParameters: {'page': '1'}),
      );
      final pattern = RouteInformation(
        uri: Uri(queryParameters: {'tab': 'books'}),
      );

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('matches when fragment is empty in pattern', () {
      final route = RouteInformation(uri: Uri(fragment: 'section1'));
      final pattern = RouteInformation(uri: Uri(fragment: ''));

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('matches when fragments match', () {
      final route = RouteInformation(uri: Uri(fragment: 'section1'));
      final pattern = RouteInformation(uri: Uri(fragment: 'section1'));

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when fragments differ', () {
      final route = RouteInformation(uri: Uri(fragment: 'section1'));
      final pattern = RouteInformation(uri: Uri(fragment: 'section2'));

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('matches when pattern state is null', () {
      final route = RouteInformation(uri: Uri(), state: {'key': 'value'});
      final pattern = RouteInformation(uri: Uri(), state: null);

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('matches when states are identical', () {
      final state = {'key': 'value'};
      final route = RouteInformation(uri: Uri(), state: state);
      final pattern = RouteInformation(uri: Uri(), state: state);

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when states differ without custom matcher', () {
      final route = RouteInformation(uri: Uri(), state: {'key': 'value1'});
      final pattern = RouteInformation(uri: Uri(), state: {'key': 'value2'});

      expect(route.matchesUrlPattern(pattern), isFalse);
    });

    test('uses custom state matcher when provided', () {
      final route = RouteInformation(uri: Uri(), state: {'id': 123});
      final pattern = RouteInformation(uri: Uri(), state: {'id': 123});

      final result = route.matchesUrlPattern(
        pattern,
        stateMatcher: (state, patternState) {
          if (state is Map && patternState is Map) {
            return state['id'] == patternState['id'];
          }
          return false;
        },
      );

      expect(result, isTrue);
    });

    test('complex matching scenario', () {
      final route = RouteInformation(
        uri: Uri(
          pathSegments: ['home', 'books', '123'],
          queryParameters: {'view': 'details', 'tab': 'reviews'},
          fragment: 'comment-5',
        ),
        state: {'scrollPosition': 100},
      );
      final pattern = RouteInformation(
        uri: Uri(
          pathSegments: ['home', 'books'],
          queryParameters: {'view': 'details'},
          fragment: '',
        ),
        state: null,
      );

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('empty path segments match', () {
      final route = RouteInformation(uri: Uri(pathSegments: []));
      final pattern = RouteInformation(uri: Uri(pathSegments: []));

      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('handles query parameters with special characters', () {
      final route = RouteInformation(
        uri: Uri(queryParameters: {'key': 'value with spaces'}),
      );
      final pattern = RouteInformation(
        uri: Uri(queryParameters: {'key': 'value with spaces'}),
      );
      expect(route.matchesUrlPattern(pattern), isTrue);
    });

    test('handles empty fragment', () {
      final route = RouteInformation(uri: Uri(fragment: ''));
      final pattern = RouteInformation(uri: Uri(fragment: ''));
      expect(route.matchesUrlPattern(pattern), isTrue);
    });
  });

  group('FlowRouteScope', () {
    testWidgets('builds with required parameters', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const TestFlowCoordinator(
          initialPagesOverride: [
            MaterialPage(
              child: FlowRouteScope(child: SizedBox()),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.byType(FlowRouteScope), findsOneWidget);

      router.dispose();
    });

    testWidgets('builds with all parameters', (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => TestFlowCoordinator(
          initialPagesOverride: [
            MaterialPage(
              child: FlowRouteScope(
                routeInformation: RouteInformation(uri: Uri.parse('/test')),
                shouldForwardChildUpdates: (routeInfo) => true,
                isActive: false,
                child: const SizedBox(),
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.byType(FlowRouteScope), findsOneWidget);

      router.dispose();
    });

    testWidgets('checks if route is top route', (tester) async {
      // This test covers line 63: isTopRoute check with ModalRoute.of(context)?.isCurrent

      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => TestFlowCoordinator(
          initialPagesOverride: [
            MaterialPage(
              key: const ValueKey('page1'),
              child: Builder(
                builder: (context) {
                  final routeStatusScope =
                      FlowRouteStatusScope.maybeOf(context);
                  return Text('isTopRoute: ${routeStatusScope?.isTopRoute}');
                },
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      // Should show that the route is top route
      expect(find.textContaining('isTopRoute:'), findsOneWidget);

      router.dispose();
    });
  });
}
