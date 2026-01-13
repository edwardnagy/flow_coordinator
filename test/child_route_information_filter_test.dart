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
      await tester.pumpAndSettle();

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
      await tester.pump();

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
      await tester.pump();

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

      expect(capturedProvider, isNotNull);

      // Verify listener can be added without errors during disposal
      if (capturedProvider != null) {
        var listenerCalled = false;
        capturedProvider!.consumedValueListenable.addListener(
          () => listenerCalled = true,
        );
        expect(listenerCalled, false); // No events yet
      }

      // Remove widget triggers disposal
      await tester.pumpWidget(Container());

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
              child: const SizedBox(),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            parentProvider2,
            child: ChildRouteInformationFilter(
              parentValueMatcher: (info) => true,
              child: const SizedBox(),
            ),
          ),
        ),
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
      await tester.pump();

      expect(capturedProvider?.childValueListenable.value, isNull);

      parentProvider.setConsumedValue(
        RouteInformation(uri: Uri.parse('/allowed')),
      );
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child2'))),
      );
      await tester.pump();

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
      await tester.pump();

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
