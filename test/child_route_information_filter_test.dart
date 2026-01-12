import 'package:flow_coordinator/src/child_route_information_filter.dart';
import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildRouteInformationFilter', () {
    testWidgets('filters route information based on predicate', (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      ChildFlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (routeInfo) =>
                  routeInfo.uri.path == '/allowed',
              child: Builder(
                builder: (context) {
                  final provider = FlowRouteInformationProvider.of(context);
                  if (provider is ChildFlowRouteInformationProvider) {
                    capturedProvider = provider;
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      // Set consumed value to allowed path
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed')),
      );
      await tester.pump();

      // Set child value - should be forwarded
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/test'))),
      );
      await tester.pump();

      // Verify child value was forwarded since parent matches predicate
      expect(capturedProvider, isNotNull);
      expect(capturedProvider?.childValueListenable.value, isNotNull);
      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/test',
      );
    });

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
                  final provider = FlowRouteInformationProvider.of(context);
                  if (provider is ChildFlowRouteInformationProvider) {
                    capturedProvider = provider;
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      // Set consumed value
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/parent')),
      );
      await tester.pump();

      // Set child value - should always be forwarded when matcher is null
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );
      await tester.pumpAndSettle();

      // Verify child value was forwarded
      expect(capturedProvider, isNotNull);
      expect(capturedProvider?.childValueListenable.value, isNotNull);
      expect(
        capturedProvider?.childValueListenable.value?.consumeOrNull()?.uri.path,
        '/child',
      );
    });

    testWidgets('updates filter when parentValueMatcher changes',
        (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);
      bool matcher1(RouteInformation info) => info.uri.path == '/path1';
      bool matcher2(RouteInformation info) => info.uri.path == '/path2';

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: matcher1,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      // Update the matcher
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: matcher2,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('disposes filter provider on dispose', (tester) async {
      final parentProvider = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => true,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(Container());

      // Should not throw errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles parent provider change', (tester) async {
      final parentProvider1 = _TestChildFlowRouteInformationProvider();
      final parentProvider2 = _TestChildFlowRouteInformationProvider();
      addTearDown(parentProvider1.dispose);
      addTearDown(parentProvider2.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider1,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => true,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      // Change parent provider
      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider2,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => true,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
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
                  final provider = FlowRouteInformationProvider.of(context);
                  if (provider is ChildFlowRouteInformationProvider) {
                    capturedProvider = provider;
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      final testRoute = RouteInformation(uri: Uri.parse('/test'));
      parentProvider.setConsumedValue(testRoute);
      await tester.pump();

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
                  final provider = FlowRouteInformationProvider.of(context);
                  if (provider is ChildFlowRouteInformationProvider) {
                    capturedProvider = provider;
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      // Set parent consumed value to disallowed path
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/disallowed')),
      );
      await tester.pump();

      // Set child value - should NOT be forwarded
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );
      await tester.pump();

      // Child value should be null since it was filtered out
      expect(capturedProvider?.childValueListenable.value, isNull);

      // Now set parent consumed value to allowed path
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed')),
      );
      await tester.pump();

      // Set child value again - should be forwarded this time
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child2'))),
      );
      await tester.pump();

      // Child value should be forwarded with correct path
      expect(capturedProvider?.childValueListenable.value, isNotNull);
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
                  final provider = FlowRouteInformationProvider.of(context);
                  if (provider is ChildFlowRouteInformationProvider) {
                    capturedProvider = provider;
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      // Parent consumed value is null, child value should not be forwarded
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child'))),
      );
      await tester.pump();

      // Verify child value was NOT forwarded since parent consumed value is
      // null
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
                  if (provider is ChildFlowRouteInformationProvider) {
                    provider.consumedValueListenable
                        .addListener(() => listenerCallCount++);
                  }
                  return const Text('Child');
                },
              ),
            ),
          ),
        ),
      );

      expect(listenerCallCount, 0);

      // Change consumed value
      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/new')),
      );
      await tester.pump();

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
