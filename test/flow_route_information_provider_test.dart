import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestProvider extends FlowRouteInformationProvider {
  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      ValueNotifier(null);
}

void main() {
  group('FlowRouteInformationProvider', () {
    testWidgets('of returns provider when found', (tester) async {
      final provider = _TestProvider();
      late FlowRouteInformationProvider result;
      await tester.pumpWidget(
        FlowRouteInformationProviderScope(
          provider,
          child: Builder(
            builder: (context) {
              result = FlowRouteInformationProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, provider);
    });

    testWidgets('of throws when not found', (tester) async {
      late FlutterError error;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowRouteInformationProvider.of(context);
            } on FlutterError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      );
      expect(
        error.toString(),
        contains('No FlowRouteInformationProviderScope found.'),
      );
    });
  });

  group('FlowRouteInformationProviderScope', () {
    test('updateShouldNotify returns true when value differs', () {
      final provider1 = _TestProvider();
      final provider2 = _TestProvider();
      final scope = FlowRouteInformationProviderScope(
        provider1,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          FlowRouteInformationProviderScope(
            provider2,
            child: const SizedBox(),
          ),
        ),
        isTrue,
      );
    });

    test('updateShouldNotify returns false when value is same', () {
      final provider = _TestProvider();
      final scope = FlowRouteInformationProviderScope(
        provider,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          FlowRouteInformationProviderScope(
            provider,
            child: const SizedBox(),
          ),
        ),
        isFalse,
      );
    });
  });
}
