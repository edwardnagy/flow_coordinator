import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock implementation for testing
class MockFlowRouteInformationProvider extends FlowRouteInformationProvider {
  MockFlowRouteInformationProvider(this._childValueNotifier);

  final ValueNotifier<Consumable<RouteInformation>?> _childValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValueNotifier;
}

class MockChildFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  MockChildFlowRouteInformationProvider(
    this._consumedValueNotifier,
    this._childValueNotifier,
  );

  final ValueNotifier<RouteInformation?> _consumedValueNotifier;
  final ValueNotifier<Consumable<RouteInformation>?> _childValueNotifier;

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      _consumedValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValueNotifier;
}

void main() {
  group('FlowRouteInformationProvider.of', () {
    testWidgets('finds provider in widget tree', (tester) async {
      final childValueNotifier =
          ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockFlowRouteInformationProvider(childValueNotifier);
      FlowRouteInformationProvider? found;

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: Builder(
            builder: (context) {
              found = FlowRouteInformationProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(provider));
      childValueNotifier.dispose();
    });

    testWidgets('throws FlutterError when no scope found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => FlowRouteInformationProvider.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('error message includes helpful hint', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowRouteInformationProvider.of(context);
              fail('Should have thrown FlutterError');
            } catch (e) {
              expect(e, isA<FlutterError>());
              expect(
                e.toString(),
                contains('FlowCoordinatorRouter'),
              );
            }
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('FlowRouteInformationProviderScope', () {
    testWidgets('provides value to descendants', (tester) async {
      final childValueNotifier =
          ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockFlowRouteInformationProvider(childValueNotifier);

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: Builder(
            builder: (context) {
              final found = FlowRouteInformationProvider.of(context);
              expect(found, same(provider));
              return const SizedBox();
            },
          ),
        ),
      );

      childValueNotifier.dispose();
    });

    testWidgets('updateShouldNotify returns true when value changes',
        (tester) async {
      final childValueNotifier1 =
          ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider1 = MockFlowRouteInformationProvider(childValueNotifier1);
      final childValueNotifier2 =
          ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider2 = MockFlowRouteInformationProvider(childValueNotifier2);
      var rebuildCount = 0;

      final builder = Builder(
        builder: (context) {
          FlowRouteInformationProvider.of(context);
          rebuildCount++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider1,
          child: builder,
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider2,
          child: builder,
        ),
      );

      expect(rebuildCount, 2);

      childValueNotifier1.dispose();
      childValueNotifier2.dispose();
    });

    testWidgets('updateShouldNotify returns false when same value',
        (tester) async {
      final childValueNotifier =
          ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockFlowRouteInformationProvider(childValueNotifier);
      var rebuildCount = 0;

      final builder = Builder(
        builder: (context) {
          FlowRouteInformationProvider.of(context);
          rebuildCount++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: builder,
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: builder,
        ),
      );

      expect(rebuildCount, 1);

      childValueNotifier.dispose();
    });
  });

  group('ChildFlowRouteInformationProvider', () {
    test('exposes consumedValueListenable', () {
      final consumedNotifier = ValueNotifier<RouteInformation?>(null);
      final childNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockChildFlowRouteInformationProvider(
        consumedNotifier,
        childNotifier,
      );

      expect(provider.consumedValueListenable, same(consumedNotifier));

      consumedNotifier.dispose();
      childNotifier.dispose();
    });

    test('exposes childValueListenable', () {
      final consumedNotifier = ValueNotifier<RouteInformation?>(null);
      final childNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockChildFlowRouteInformationProvider(
        consumedNotifier,
        childNotifier,
      );

      expect(provider.childValueListenable, same(childNotifier));

      consumedNotifier.dispose();
      childNotifier.dispose();
    });

    testWidgets('works as FlowRouteInformationProvider', (tester) async {
      final consumedNotifier = ValueNotifier<RouteInformation?>(null);
      final childNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);
      final provider = MockChildFlowRouteInformationProvider(
        consumedNotifier,
        childNotifier,
      );

      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: Builder(
            builder: (context) {
              final found = FlowRouteInformationProvider.of(context);
              expect(found, same(provider));
              expect(found, isA<ChildFlowRouteInformationProvider>());
              return const SizedBox();
            },
          ),
        ),
      );

      consumedNotifier.dispose();
      childNotifier.dispose();
    });
  });
}
