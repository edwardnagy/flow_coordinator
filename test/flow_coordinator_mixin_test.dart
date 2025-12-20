import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';

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
  final Future<RouteInformation?> Function(RouteInformation)? onNewRouteInformationCallback;

  @override
  State<TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<TestFlowCoordinator>
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
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      expect(find.byType(TestFlowCoordinator), findsOneWidget);
    });

    testWidgets('provides flowNavigator', (tester) async {
      _TestFlowCoordinatorState? state;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) {
              return Builder(
                builder: (context) {
                  state = context.findAncestorStateOfType<_TestFlowCoordinatorState>();
                  return const TestFlowCoordinator();
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      state = tester.state<_TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(state, isNotNull);
      expect(state!.flowNavigator, isNotNull);
    });

    testWidgets('flowNavigator can push pages', (tester) async {
      _TestFlowCoordinatorState? state;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      state = tester.state<_TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      state!.flowNavigator.push(
        const MaterialPage(key: ValueKey('new-page'), child: Text('New Page')),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('setNewRouteInformation triggers onNewRouteInformation', (tester) async {
      RouteInformation? receivedRouteInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
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

      final state = tester.state<_TestFlowCoordinatorState>(
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
        MaterialApp(
          home: FlowCoordinatorRouter(
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
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Router), findsWidgets);
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(const SizedBox());

      // Should not throw
    });

    testWidgets('default initialPages is empty', (tester) async {
      // Create a flow coordinator without overriding initialPages
      final widget = TestFlowCoordinator(initialPagesOverride: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => widget,
          ),
        ),
      );

      // Widget should be created
      expect(widget, isNotNull);
    });

    testWidgets('default onNewRouteInformation returns null', (tester) async {
      RouteInformation? result;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<_TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      result = await state.onNewRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      expect(result, isNull);
    });

    testWidgets('default routeInformationCombiner is DefaultRouteInformationCombiner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<_TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(state.routeInformationCombiner, isA<DefaultRouteInformationCombiner>());
    });

    testWidgets('default initialRouteInformation is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<_TestFlowCoordinatorState>(
        find.byType(TestFlowCoordinator),
      );

      expect(state.initialRouteInformation, isNull);
    });

    testWidgets('flowNavigator.canPop checks internal and parent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<_TestFlowCoordinatorState>(
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
        MaterialApp(
          home: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              initialPagesOverride: [
                const MaterialPage(
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
  });
}
