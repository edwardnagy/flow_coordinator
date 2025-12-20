import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/child_route_information_filter.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flow_coordinator/src/consumable.dart';

// Mock implementation for testing
class MockChildFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  MockChildFlowRouteInformationProvider({
    RouteInformation? initialConsumedValue,
    Consumable<RouteInformation>? initialChildValue,
  })  : _consumedValueNotifier = ValueNotifier(initialConsumedValue),
        _childValueNotifier = ValueNotifier(initialChildValue);

  final ValueNotifier<RouteInformation?> _consumedValueNotifier;
  final ValueNotifier<Consumable<RouteInformation>?> _childValueNotifier;

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

void main() {
  group('ChildRouteInformationFilter', () {
    testWidgets('builds with required parameters', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider();

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: const ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: SizedBox(),
          ),
        ),
      );

      expect(find.byType(ChildRouteInformationFilter), findsOneWidget);

      parentProvider.dispose();
    });

    testWidgets('forwards all updates when parentValueMatcher is null', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider();
      RouteInformation? receivedChildValue;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: Builder(
              builder: (context) {
                final provider = FlowRouteInformationProvider.of(context);
                receivedChildValue = provider.childValueListenable.value?.consumeOrNull();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final routeInfo = RouteInformation(uri: Uri.parse('/test'));
      parentProvider.setChildValue(Consumable(routeInfo));

      await tester.pump();

      expect(receivedChildValue, isNotNull);
      parentProvider.dispose();
    });

    testWidgets('filters updates based on parentValueMatcher', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider(
        initialConsumedValue: RouteInformation(uri: Uri.parse('/home')),
      );
      RouteInformation? receivedChildValue;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: (routeInfo) => routeInfo.uri.path == '/home',
            child: Builder(
              builder: (context) {
                final provider = FlowRouteInformationProvider.of(context);
                receivedChildValue = provider.childValueListenable.value?.consumeOrNull();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final routeInfo = RouteInformation(uri: Uri.parse('/child'));
      parentProvider.setChildValue(Consumable(routeInfo));

      await tester.pump();

      // Should forward because consumed value matches
      expect(receivedChildValue, isNotNull);

      parentProvider.dispose();
    });

    testWidgets('blocks updates when parentValueMatcher returns false', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider(
        initialConsumedValue: RouteInformation(uri: Uri.parse('/other')),
      );
      int buildCount = 0;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: (routeInfo) => routeInfo.uri.path == '/home',
            child: Builder(
              builder: (context) {
                buildCount++;
                FlowRouteInformationProvider.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final initialBuildCount = buildCount;

      final routeInfo = RouteInformation(uri: Uri.parse('/child'));
      parentProvider.setChildValue(Consumable(routeInfo));

      await tester.pump();

      // Should not trigger rebuild because matcher returned false
      expect(buildCount, initialBuildCount);

      parentProvider.dispose();
    });

    testWidgets('copies consumed value from parent', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider(
        initialConsumedValue: RouteInformation(uri: Uri.parse('/parent')),
      );
      RouteInformation? receivedConsumedValue;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: Builder(
              builder: (context) {
                final provider = FlowRouteInformationProvider.of(context);
                if (provider is ChildFlowRouteInformationProvider) {
                  receivedConsumedValue = provider.consumedValueListenable.value;
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(receivedConsumedValue, isNotNull);
      expect(receivedConsumedValue!.uri.path, equals('/parent'));

      parentProvider.dispose();
    });

    testWidgets('updates when consumed value changes', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider(
        initialConsumedValue: RouteInformation(uri: Uri.parse('/first')),
      );
      RouteInformation? receivedConsumedValue;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: Builder(
              builder: (context) {
                final provider = FlowRouteInformationProvider.of(context);
                if (provider is ChildFlowRouteInformationProvider) {
                  receivedConsumedValue = provider.consumedValueListenable.value;
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      parentProvider.setConsumedValue(RouteInformation(uri: Uri.parse('/second')));

      await tester.pump();

      expect(receivedConsumedValue!.uri.path, equals('/second'));

      parentProvider.dispose();
    });

    testWidgets('re-evaluates when parentValueMatcher changes', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider(
        initialConsumedValue: RouteInformation(uri: Uri.parse('/home')),
      );
      bool shouldForward = false;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: (routeInfo) => shouldForward,
            child: const SizedBox(),
          ),
        ),
      );

      // Set child value when matcher returns false
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child1'))),
      );

      await tester.pump();

      // Now update matcher to return true
      shouldForward = true;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: ChildRouteInformationFilter(
            parentValueMatcher: (routeInfo) => shouldForward,
            child: const SizedBox(),
          ),
        ),
      );

      // Set another child value
      parentProvider.setChildValue(
        Consumable(RouteInformation(uri: Uri.parse('/child2'))),
      );

      await tester.pump();

      parentProvider.dispose();
    });

    testWidgets('disposes filter provider on dispose', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider();

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: const ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: SizedBox(),
          ),
        ),
      );

      // Remove the widget tree
      await tester.pumpWidget(const SizedBox());

      // Should not throw
      parentProvider.dispose();
    });

    testWidgets('handles null consumed value', (tester) async {
      final parentProvider = MockChildFlowRouteInformationProvider();

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          parentProvider,
          child: const ChildRouteInformationFilter(
            parentValueMatcher: null,
            child: SizedBox(),
          ),
        ),
      );

      expect(find.byType(ChildRouteInformationFilter), findsOneWidget);

      parentProvider.dispose();
    });
  });
}
