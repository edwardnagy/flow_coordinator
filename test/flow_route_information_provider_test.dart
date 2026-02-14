import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouteInformationProvider', () {
    testWidgets('of throws error when scope not found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(),
        ),
      );

      final context = tester.element(find.byType(Container));
      expect(
        () => FlowRouteInformationProvider.of(context),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('of returns provider when scope exists', (tester) async {
      final provider = _TestFlowRouteInformationProvider();
      addTearDown(provider.dispose);
      FlowRouteInformationProvider? capturedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            provider,
            child: Builder(
              builder: (context) {
                capturedProvider = FlowRouteInformationProvider.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedProvider, provider);
    });
  });

  group('FlowRouteInformationProviderScope', () {
    testWidgets('provides value to descendants', (tester) async {
      final provider = _TestFlowRouteInformationProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FlowRouteInformationProviderScope(
            provider,
            child: Builder(
              builder: (context) {
                final found = FlowRouteInformationProvider.of(context);
                return Text('Found: ${found == provider}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Found: true'), findsOneWidget);
    });

    test('updateShouldNotify returns true when value changes', () {
      final provider1 = _TestFlowRouteInformationProvider();
      final provider2 = _TestFlowRouteInformationProvider();
      addTearDown(provider1.dispose);
      addTearDown(provider2.dispose);
      final scope1 = FlowRouteInformationProviderScope(
        provider1,
        child: const SizedBox(),
      );
      final scope2 = FlowRouteInformationProviderScope(
        provider2,
        child: const SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), true);
    });

    test('updateShouldNotify returns false when value same', () {
      final provider = _TestFlowRouteInformationProvider();
      addTearDown(provider.dispose);
      final scope1 = FlowRouteInformationProviderScope(
        provider,
        child: const SizedBox(),
      );
      final scope2 = FlowRouteInformationProviderScope(
        provider,
        child: const SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), false);
    });
  });
}

class _TestFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  final _consumedValue = ValueNotifier<RouteInformation?>(null);
  final _childValue = ValueNotifier<Consumable<RouteInformation>?>(null);

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      _consumedValue;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValue;

  void dispose() {
    _consumedValue.dispose();
    _childValue.dispose();
  }
}
