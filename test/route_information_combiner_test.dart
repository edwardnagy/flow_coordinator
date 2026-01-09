import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultRouteInformationCombiner', () {
    test('combine returns combined path', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent'));
      final childRoute = RouteInformation(uri: Uri.parse('/child'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      // Uri with pathSegments doesn't include leading slash
      expect(result.uri.pathSegments, ['parent', 'child']);
    });

    test('combine preserves current query params if child has none', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent?a=1'));
      final childRoute = RouteInformation(uri: Uri.parse('/child'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.uri.pathSegments, ['parent', 'child']);
      expect(result.uri.queryParameters['a'], '1');
    });

    test('combine merges query params', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent?a=1&b=2'));
      final childRoute = RouteInformation(uri: Uri.parse('/child?b=3&c=4'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.uri.queryParameters['a'], '1');
      expect(result.uri.queryParameters['b'], '3'); // Child overrides
      expect(result.uri.queryParameters['c'], '4');
    });

    test('combine handles trailing slashes', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent/'));
      final childRoute = RouteInformation(uri: Uri.parse('/child'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      // Trailing slash on the parent produces an empty path segment that is
      // preserved by Uri, so we assert the exact behavior here.
      expect(result.uri.pathSegments, ['parent', '', 'child']);
    });

    test('combine handles leading slashes in child', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent'));
      final childRoute = RouteInformation(uri: Uri.parse('/child'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.uri.pathSegments, ['parent', 'child']);
    });

    testWidgets('of throws when RouteInformationCombinerScope not found',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      final context = tester.element(find.byType(SizedBox));

      expect(
        () => RouteInformationCombiner.of(context),
        throwsA(isA<FlutterError>()),
      );
    });

    test('combine handles empty paths', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse(''));
      final childRoute = RouteInformation(uri: Uri.parse(''));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.uri.pathSegments, isEmpty);
    });

    test('combine handles fragment from child', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(uri: Uri.parse('/parent'));
      final childRoute = RouteInformation(uri: Uri.parse('/child#section'));

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.uri.fragment, 'section');
    });

    test('combine uses child state', () {
      const combiner = DefaultRouteInformationCombiner();
      final parentRoute = RouteInformation(
        uri: Uri.parse('/parent'),
        state: 'parent state',
      );
      final childRoute = RouteInformation(
        uri: Uri.parse('/child'),
        state: 'child state',
      );

      final result = combiner.combine(
        currentRouteInformation: parentRoute,
        childRouteInformation: childRoute,
      );

      expect(result.state, 'child state');
    });

    testWidgets(
        'RouteInformationCombinerScope provides combiner to descendants',
        (tester) async {
      const combiner = DefaultRouteInformationCombiner();
      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationCombinerScope(
            combiner,
            child: Builder(
              builder: (context) {
                final found = RouteInformationCombiner.of(context);
                return Text('Found: ${found == combiner}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Found: true'), findsOneWidget);
    });

    test(
        'RouteInformationCombinerScope updateShouldNotify returns true '
        'when value changes', () {
      const combiner1 = DefaultRouteInformationCombiner();
      const combiner2 = _CustomRouteInformationCombiner();
      const scope1 = RouteInformationCombinerScope(
        combiner1,
        child: SizedBox(),
      );
      const scope2 = RouteInformationCombinerScope(
        combiner2,
        child: SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), true);
    });

    test(
        'RouteInformationCombinerScope updateShouldNotify returns false '
        'when value same', () {
      const combiner = DefaultRouteInformationCombiner();
      const scope1 = RouteInformationCombinerScope(
        combiner,
        child: SizedBox(),
      );
      const scope2 = RouteInformationCombinerScope(
        combiner,
        child: SizedBox(),
      );

      expect(scope2.updateShouldNotify(scope1), false);
    });
  });
}

class _CustomRouteInformationCombiner implements RouteInformationCombiner {
  const _CustomRouteInformationCombiner();

  @override
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  }) {
    return childRouteInformation;
  }
}
