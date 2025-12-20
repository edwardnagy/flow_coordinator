import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';

/// Additional tests for edge cases and scenarios not covered by main test files
void main() {
  group('Edge Case Tests', () {
    group('Consumable edge cases', () {
      test('works with null value', () {
        final consumable = Consumable<String?>(null);
        expect(consumable.consumeOrNull(), isNull);
        expect(consumable.consumeOrNull(), isNull);
      });

      test('works with complex nested types', () {
        final value = {
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };
        final consumable = Consumable(value);
        expect(consumable.consumeOrNull(), equals(value));
      });
    });

    group('RouteInformation edge cases', () {
      testWidgets('handles empty URIs in combiner', (tester) async {
        const combiner = DefaultRouteInformationCombiner();
        final result = combiner.combine(
          currentRouteInformation: RouteInformation(uri: Uri()),
          childRouteInformation: RouteInformation(uri: Uri()),
        );
        expect(result.uri.pathSegments, isEmpty);
        expect(result.uri.queryParameters, isEmpty);
      });

      test('matchesUrlPattern handles query parameters with special characters', () {
        final route = RouteInformation(
          uri: Uri(queryParameters: {'key': 'value with spaces'}),
        );
        final pattern = RouteInformation(
          uri: Uri(queryParameters: {'key': 'value with spaces'}),
        );
        expect(route.matchesUrlPattern(pattern), isTrue);
      });

      test('matchesUrlPattern handles empty fragment', () {
        final route = RouteInformation(uri: Uri(fragment: ''));
        final pattern = RouteInformation(uri: Uri(fragment: ''));
        expect(route.matchesUrlPattern(pattern), isTrue);
      });
    });

    group('FlowNavigator edge cases', () {
      testWidgets('pop with null result', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
            const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
          ],
          contextDescriptionProvider: () => 'Test',
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(builder: delegate.build),
          ),
        );

        await tester.pumpAndSettle();

        delegate.pop<String>();
        await tester.pumpAndSettle();

        delegate.dispose();
      });

      testWidgets('popInternally with result', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
            const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
          ],
          contextDescriptionProvider: () => 'Test',
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(builder: delegate.build),
          ),
        );

        await tester.pumpAndSettle();

        delegate.popInternally<String>('result');
        await tester.pumpAndSettle();

        delegate.dispose();
      });

      testWidgets('maybePopInternally with result', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
            const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
          ],
          contextDescriptionProvider: () => 'Test',
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(builder: delegate.build),
          ),
        );

        await tester.pumpAndSettle();

        final result = await delegate.maybePopInternally<String>('result');
        expect(result, isTrue);

        delegate.dispose();
      });
    });

    group('FlowCoordinatorRouter edge cases', () {
      testWidgets('handles null state', (tester) async {
        final router = FlowCoordinatorRouter(
          initialState: null,
          homeBuilder: (context) => const Text('Home'),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        expect(find.text('Home'), findsOneWidget);

        router.dispose();
      });

      testWidgets('handles complex initial state', (tester) async {
        final router = FlowCoordinatorRouter(
          initialState: {
            'nested': {
              'value': [1, 2, 3]
            }
          },
          homeBuilder: (context) => const Text('Home'),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        expect(find.text('Home'), findsOneWidget);

        router.dispose();
      });

      testWidgets('handles URI with query parameters', (tester) async {
        final router = FlowCoordinatorRouter(
          initialUri: Uri.parse('/path?key1=value1&key2=value2'),
          homeBuilder: (context) => const Text('Home'),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        expect(find.text('Home'), findsOneWidget);

        router.dispose();
      });

      testWidgets('handles URI with fragment', (tester) async {
        final router = FlowCoordinatorRouter(
          initialUri: Uri.parse('/path#section'),
          homeBuilder: (context) => const Text('Home'),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        expect(find.text('Home'), findsOneWidget);

        router.dispose();
      });
    });

    group('FlowCoordinatorMixin edge cases', () {
      testWidgets('handles rapid route information updates', (tester) async {
        var updateCount = 0;

        final router = FlowCoordinatorRouter(
          homeBuilder: (context) => TestFlowCoordinator(
            onNewRouteInformationCallback: (info) {
              updateCount++;
              return Future.value(null);
            },
          ),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        await tester.pumpAndSettle();

        final state = tester.state<TestFlowCoordinatorState>(
          find.byType(TestFlowCoordinator),
        );

        // Send multiple rapid updates
        for (var i = 0; i < 5; i++) {
          state.setNewRouteInformation(
            RouteInformation(uri: Uri.parse('/route$i')),
          );
        }

        await tester.pumpAndSettle();

        expect(updateCount, greaterThanOrEqualTo(5));

        router.dispose();
      });

      testWidgets('handles empty page list gracefully with assertion', (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (context) => TestFlowCoordinator(
            initialPagesOverride: [],
          ),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        // Should trigger assertion in build
        expect(tester.takeException(), isA<AssertionError>());

        router.dispose();
      });
    });

    group('RootRouteInformationReporterDelegate edge cases', () {
      testWidgets('handles multiple simultaneous reports', (tester) async {
        final delegate = RootRouteInformationReporterDelegate();

        // Schedule multiple reports in the same frame
        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/first')),
        );
        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/second')),
        );
        delegate.childReportsRouteInformation(
          RouteInformation(uri: Uri.parse('/third')),
        );

        await tester.pump();

        // Should report the last one
        expect(delegate.reportedRouteInformation!.uri.path, equals('/third'));

        delegate.dispose();
      });

      testWidgets('prefixes various URI formats correctly', (tester) async {
        final delegate = RootRouteInformationReporterDelegate();

        final testCases = [
          ('test', '/test'),
          ('test/path', '/test/path'),
          ('/test', '/test'),
          ('', '/'),
        ];

        for (final (input, expected) in testCases) {
          delegate.childReportsRouteInformation(
            RouteInformation(uri: Uri.parse(input)),
          );
          await tester.pump();
          expect(
            delegate.reportedRouteInformation!.uri.toString(),
            equals(expected),
          );
        }

        delegate.dispose();
      });
    });
  });
}

// Helper classes
class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({
    super.key,
    this.initialPagesOverride,
    this.onNewRouteInformationCallback,
  });

  final List<Page>? initialPagesOverride;
  final Future<RouteInformation?> Function(RouteInformation)?
      onNewRouteInformationCallback;

  @override
  State<TestFlowCoordinator> createState() => TestFlowCoordinatorState();
}

class TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages =>
      widget.initialPagesOverride ??
      [const MaterialPage(key: ValueKey('initial'), child: SizedBox())];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    if (widget.onNewRouteInformationCallback != null) {
      return widget.onNewRouteInformationCallback!(routeInformation);
    }
    return super.onNewRouteInformation(routeInformation);
  }
}
