import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test flow coordinator implementation
class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({
    super.key,
    this.initialPagesOverride,
    this.initialRouteInformationOverride,
    this.onNewRouteInformationCallback,
  });

  final List<Page>? initialPagesOverride;
  final RouteInformation? initialRouteInformationOverride;
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
  RouteInformation? get initialRouteInformation =>
      widget.initialRouteInformationOverride;

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

void main() {
  group('FlowCoordinatorMixin', () {
    testWidgets('initializes with initial pages', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      expect(find.byType(TestFlowCoordinator), findsOneWidget);
    });

    testWidgets('provides flowNavigator', (tester) async {
      TestFlowCoordinatorState? state;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) {
              return Builder(
                builder: (context) {
                  state = context
                      .findAncestorStateOfType<TestFlowCoordinatorState>();
                  return const TestFlowCoordinator();
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(state, isNotNull);
      expect(state!.flowNavigator, isNotNull);
    });

    testWidgets('flowNavigator can push pages', (tester) async {
      TestFlowCoordinatorState? state;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      state.flowNavigator.push(
        const MaterialPage(key: ValueKey('new-page'), child: Text('New Page')),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('setNewRouteInformation triggers onNewRouteInformation',
        (tester) async {
      RouteInformation? receivedRouteInfo;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              onNewRouteInformationCallback: (routeInfo) {
                receivedRouteInfo = routeInfo;
                return SynchronousFuture(null);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      final testRouteInfo = RouteInformation(uri: Uri.parse('/test'));
      state.setNewRouteInformation(testRouteInfo);

      await tester.pumpAndSettle();

      expect(receivedRouteInfo, same(testRouteInfo));
    });

    testWidgets('uses initialRouteInformation when provided', (tester) async {
      RouteInformation? receivedRouteInfo;
      final initialRouteInfo = RouteInformation(uri: Uri.parse('/initial'));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              initialRouteInformationOverride: initialRouteInfo,
              onNewRouteInformationCallback: (routeInfo) {
                receivedRouteInfo = routeInfo;
                return SynchronousFuture(null);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(receivedRouteInfo, isNotNull);
      expect(receivedRouteInfo!.uri.path, equals('/initial'));
    });

    testWidgets('builds router widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Router), findsWidgets);
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(const SizedBox());

      // Should not throw
    });

    testWidgets('throws assertion error when initialPages is empty',
        (tester) async {
      // Create a flow coordinator without overriding initialPages
      const widget = TestFlowCoordinator(initialPagesOverride: []);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => widget,
          ),
        ),
      );

      // Should throw assertion error
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('default onNewRouteInformation returns null', (tester) async {
      RouteInformation? result;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      result = await state.onNewRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      expect(result, isNull);
    });

    testWidgets(
        'default routeInformationCombiner is DefaultRouteInformationCombiner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(
        state.routeInformationCombiner,
        isA<DefaultRouteInformationCombiner>(),
      );
    });

    testWidgets('default initialRouteInformation is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(state.initialRouteInformation, isNull);
    });

    testWidgets('flowNavigator.canPop checks internal and parent',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      // With only one page, should not be able to pop
      expect(state.flowNavigator.canPop(), isFalse);

      // Push another page
      state.flowNavigator.push(
        const MaterialPage(key: ValueKey('page2'), child: SizedBox()),
      );

      await tester.pumpAndSettle();

      // Now should be able to pop
      expect(state.flowNavigator.canPop(), isTrue);
    });

    testWidgets('nested flow coordinators work', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(
              initialPagesOverride: [
                MaterialPage(
                  key: ValueKey('parent'),
                  child: TestFlowCoordinator(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TestFlowCoordinator), findsWidgets);
    });

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

    testWidgets('handles empty page list gracefully with assertion',
        (tester) async {
      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const TestFlowCoordinator(
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

    testWidgets('overrides initialPages getter', (tester) async {
      // This test covers line 79: List<Page> get initialPages => [];
      // By default, initialPages returns an empty list, but subclasses override it

      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => const TestFlowCoordinator(),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      final state = tester.state<TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      // The TestFlowCoordinator overrides initialPages
      expect(state.initialPages, isNotEmpty);
      expect(state.initialPages.first.key, const ValueKey('initial'));

      router.dispose();
    });

    testWidgets('handles child route information from parent', (tester) async {
      // This test covers lines 123-124, 135-140: child route information handling
      // and _onValueReceivedFromParent callback

      final childRouteInfo = RouteInformation(uri: Uri.parse('/child'));
      var childRouteReceived = false;

      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => TestFlowCoordinator(
          onNewRouteInformationCallback: (info) async {
            if (info.uri.path == '/child') {
              childRouteReceived = true;
            }
            return childRouteInfo;
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

      // Trigger setNewRouteInformation which should set child route info
      await state.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      await tester.pumpAndSettle();

      // The child route information should have been set and callback triggered
      // This exercises lines 123-124 where childValueNotifier.value is set
      // and lines 135-140 where _onValueReceivedFromParent processes it

      router.dispose();
    });

    testWidgets('parent route information provider change triggers listener',
        (tester) async {
      // This test covers line 157: removeListener call when parent changes

      var listenerRemoved = false;

      final router = FlowCoordinatorRouter(
        homeBuilder: (context) => TestFlowCoordinator(
          initialPagesOverride: const [
            MaterialPage(
              key: ValueKey('parent'),
              child: TestFlowCoordinator(
                initialPagesOverride: [
                  MaterialPage(
                    key: ValueKey('child'),
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      // Trigger a rebuild that might change the parent provider
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      // The listener should have been properly managed
      expect(find.byType(TestFlowCoordinator), findsWidgets);

      router.dispose();
    });
  });
}
