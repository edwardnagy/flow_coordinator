import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationCombiner', () {
    testWidgets('of returns combiner when found', (tester) async {
      const combiner = DefaultRouteInformationCombiner();
      late RouteInformationCombiner result;
      await tester.pumpWidget(
        RouteInformationCombinerScope(
          combiner,
          child: Builder(
            builder: (context) {
              result = RouteInformationCombiner.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, combiner);
    });

    testWidgets('of throws when not found', (tester) async {
      late FlutterError error;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              RouteInformationCombiner.of(context);
            } on FlutterError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      );
      expect(
        error.toString(),
        contains('No RouteInformationCombinerScope found.'),
      );
    });
  });

  group('DefaultRouteInformationCombiner', () {
    const combiner = DefaultRouteInformationCombiner();

    test('concatenates path segments from both routes', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(uri: Uri.parse('/home')),
        childRouteInformation: RouteInformation(uri: Uri.parse('/details')),
      );
      expect(result.uri.path, 'home/details');
    });

    test('omits path segments when both are empty', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(uri: Uri()),
        childRouteInformation: RouteInformation(uri: Uri()),
      );
      expect(result.uri.pathSegments, isEmpty);
    });

    test(
      'merges query parameters with child overriding current',
      () {
        final result = combiner.combine(
          currentRouteInformation: RouteInformation(
            uri: Uri.parse('/a?key=parent&only=parent'),
          ),
          childRouteInformation: RouteInformation(
            uri: Uri.parse('/b?key=child&extra=child'),
          ),
        );
        expect(result.uri.queryParameters, {
          'key': 'child',
          'only': 'parent',
          'extra': 'child',
        });
      },
    );

    test('omits query parameters when both are empty', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(uri: Uri.parse('/a')),
        childRouteInformation: RouteInformation(uri: Uri.parse('/b')),
      );
      expect(result.uri.queryParameters, isEmpty);
    });

    test('uses child fragment when present', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(uri: Uri.parse('/a')),
        childRouteInformation: RouteInformation(uri: Uri.parse('/b#section')),
      );
      expect(result.uri.fragment, 'section');
    });

    test('omits fragment when child fragment is empty', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(uri: Uri.parse('/a#parent')),
        childRouteInformation: RouteInformation(uri: Uri.parse('/b')),
      );
      expect(result.uri.fragment, isEmpty);
    });

    test('uses child state', () {
      final result = combiner.combine(
        currentRouteInformation: RouteInformation(
          uri: Uri.parse('/a'),
          state: 'parentState',
        ),
        childRouteInformation: RouteInformation(
          uri: Uri.parse('/b'),
          state: 'childState',
        ),
      );
      expect(result.state, 'childState');
    });
  });

  group('RouteInformationCombinerScope', () {
    test('updateShouldNotify returns true when value differs', () {
      final combiner1 = _CustomCombiner();
      final combiner2 = _CustomCombiner();
      final scope = RouteInformationCombinerScope(
        combiner1,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          RouteInformationCombinerScope(
            combiner2,
            child: const SizedBox(),
          ),
        ),
        isTrue,
      );
    });

    test('updateShouldNotify returns false when value is same', () {
      final combiner = _CustomCombiner();
      final scope = RouteInformationCombinerScope(
        combiner,
        child: const SizedBox(),
      );
      expect(
        scope.updateShouldNotify(
          RouteInformationCombinerScope(
            combiner,
            child: const SizedBox(),
          ),
        ),
        isFalse,
      );
    });
  });
}

class _CustomCombiner implements RouteInformationCombiner {
  @override
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  }) =>
      childRouteInformation;
}
