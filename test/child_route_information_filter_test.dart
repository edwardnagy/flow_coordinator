import 'package:flow_coordinator/src/child_route_information_filter.dart';
import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildRouteInformationFilter', () {
    testWidgets('forwards all updates when parentValueMatcher is null',
        (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: null,
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/parent')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );

      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/child',
      );
    });

    testWidgets('updates filter when parentValueMatcher changes',
        (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => info.uri.path == '/allowed1',
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed1')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );

      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/child',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => info.uri.path == '/allowed2',
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed2')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child2'))),
      );

      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/child2',
      );
    });

    testWidgets('disposes filter provider on dispose', (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => true,
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Verify provider is functional before disposal
      var listenerCallCount = 0;
      capturedProvider!.consumedValueListenable.addListener(
        () => listenerCallCount++,
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/test')),
      );
      expect(listenerCallCount, greaterThan(0));

      // Remove widget triggers disposal
      await tester.pumpWidget(Container());

      // After disposal, updating parent should not cause issues
      // (listeners were properly removed). We verify this by checking
      // the operation completes without error.
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/after-dispose')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/after-dispose-child'))),
      );

      // Pump to process any pending callbacks - test passes if no crash
      await tester.pump();
    });

    testWidgets('handles parent provider change', (tester) async {
      final parentProvider1 = _TestChildFlowRouteInformationProvider();
      final parentProvider2 = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider1.dispose);
      addTearDown(parentProvider2.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider1,
            child: ChildRouteInformationFilter(
              parentValueMatcher: null, // null matcher forwards all updates
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Set value on first parent
      parentProvider1.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/from-parent1'))),
      );
      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/from-parent1',
      );

      // Switch to second parent
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider2,
            child: ChildRouteInformationFilter(
              parentValueMatcher: null,
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Verify child receives values from new parent
      parentProvider2.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/from-parent2'))),
      );
      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/from-parent2',
      );

      // Verify old parent updates don't affect the child anymore
      parentProvider1.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/old-parent-update'))),
      );
      // New value from parent2 should be received, not affected by parent1
      parentProvider2.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/still-parent2'))),
      );
      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/still-parent2',
      );
    });

    testWidgets('copies consumed value from parent', (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: null,
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      final testRoute = RouteInformation(uri: Uri.parse('/test'));
      parentProvider.setConsumedValue(testRoute);

      expect(capturedProvider?.consumedValueListenable.value, testRoute);
    });

    testWidgets('filters child value based on parent consumed value',
        (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => info.uri.path == '/allowed',
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/disallowed')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );

      expect(capturedProvider?.childValueListenable.value, isNull);

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child2'))),
      );

      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/child2',
      );
    });

    testWidgets('handles null parent consumed value with matcher',
        (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => info.uri.path == '/test',
              child: Builder(
                builder: (context) {
                  capturedProvider =
                      FlowRouteInformationProvider.of(context) as
                          ChildFlowRouteInformationProvider;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );

      expect(capturedProvider?.childValueListenable.value, isNull);
    });

    testWidgets('listener updates when parent values change', (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      var listenerCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: null,
              child: Builder(
                builder: (context) {
                  final provider = FlowRouteInformationProvider.of(context);
                  (provider as ChildFlowRouteInformationProvider)
                      .consumedValueListenable
                      .addListener(() => listenerCallCount++);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/new')),
      );

      expect(listenerCallCount, greaterThan(0));
    });
  });
}

class _TestChildFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  final _consumedValueNotifier = ValueNotifier<RouteInformation?>(null);
  final _childValueNotifier =
      ValueNotifier<Consumable<RouteInformation>?>(null);

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      _consumedValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValueNotifier;

  void setConsumedValue(RouteInformation? value) {
    _consumedValueNotifier.value = value;
  }

  void setChildValue(Consumable<RouteInformation>? value) {
    _childValueNotifier.value = value;
  }

  void dispose() {
    _consumedValueNotifier.dispose();
    _childValueNotifier.dispose();
  }
}
