import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';

void main() {
  group('DefaultRouteInformationCombiner', () {
    late DefaultRouteInformationCombiner combiner;

    setUp(() {
      combiner = const DefaultRouteInformationCombiner();
    });

    test('combines path segments', () {
      final current = RouteInformation(uri: Uri(pathSegments: ['home']));
      final child = RouteInformation(uri: Uri(pathSegments: ['details', '123']));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.pathSegments, equals(['home', 'details', '123']));
    });

    test('combines query parameters with child overriding current', () {
      final current = RouteInformation(
        uri: Uri(queryParameters: {'tab': 'books', 'filter': 'all'}),
      );
      final child = RouteInformation(
        uri: Uri(queryParameters: {'filter': 'recent', 'id': '42'}),
      );

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.queryParameters, equals({
        'tab': 'books',
        'filter': 'recent', // child overrides current
        'id': '42',
      }));
    });

    test('uses child fragment when present', () {
      final current = RouteInformation(uri: Uri(fragment: 'section1'));
      final child = RouteInformation(uri: Uri(fragment: 'section2'));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.fragment, equals('section2'));
    });

    test('uses no fragment when child fragment is empty', () {
      final current = RouteInformation(uri: Uri(fragment: 'section1'));
      final child = RouteInformation(uri: Uri(fragment: ''));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.fragment, isEmpty);
    });

    test('uses child state', () {
      final current = RouteInformation(
        uri: Uri(),
        state: {'current': 'data'},
      );
      final child = RouteInformation(
        uri: Uri(),
        state: {'child': 'data'},
      );

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.state, equals({'child': 'data'}));
    });

    test('handles empty path segments correctly', () {
      final current = RouteInformation(uri: Uri(pathSegments: []));
      final child = RouteInformation(uri: Uri(pathSegments: []));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.pathSegments, isEmpty);
    });

    test('handles empty query parameters', () {
      final current = RouteInformation(uri: Uri(queryParameters: {}));
      final child = RouteInformation(uri: Uri(queryParameters: {}));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.queryParameters, isEmpty);
    });

    test('combines complete example from documentation', () {
      // From docs: Current route: /home?tab=books
      //            Child route: /123?view=details#reviews
      //            Combined result: /home/123?tab=books&view=details#reviews

      final current = RouteInformation(
        uri: Uri(pathSegments: ['home'], queryParameters: {'tab': 'books'}),
      );
      final child = RouteInformation(
        uri: Uri(
          pathSegments: ['123'],
          queryParameters: {'view': 'details'},
          fragment: 'reviews',
        ),
      );

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.pathSegments, equals(['home', '123']));
      expect(result.uri.queryParameters, equals({
        'tab': 'books',
        'view': 'details',
      }));
      expect(result.uri.fragment, equals('reviews'));
    });

    test('child with path segments and current without', () {
      final current = RouteInformation(uri: Uri());
      final child = RouteInformation(uri: Uri(pathSegments: ['child', 'path']));

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.pathSegments, equals(['child', 'path']));
    });

    test('current with path segments and child without', () {
      final current = RouteInformation(uri: Uri(pathSegments: ['parent']));
      final child = RouteInformation(uri: Uri());

      final result = combiner.combine(
        currentRouteInformation: current,
        childRouteInformation: child,
      );

      expect(result.uri.pathSegments, equals(['parent']));
    });

    test('const constructor allows compile-time constant', () {
      const combiner1 = DefaultRouteInformationCombiner();
      const combiner2 = DefaultRouteInformationCombiner();
      expect(combiner1, equals(combiner2));
    });
  });

  group('RouteInformationCombiner.of', () {
    testWidgets('finds RouteInformationCombiner in widget tree', (tester) async {
      const combiner = DefaultRouteInformationCombiner();
      RouteInformationCombiner? found;

      await tester.pumpWidget(
        RouteInformationCombinerScope(
          combiner,
          child: Builder(
            builder: (context) {
              found = RouteInformationCombiner.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(combiner));
    });

    testWidgets('throws FlutterError when no scope found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => RouteInformationCombiner.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('RouteInformationCombinerScope', () {
    testWidgets('updates when value changes', (tester) async {
      const combiner1 = DefaultRouteInformationCombiner();
      const combiner2 = DefaultRouteInformationCombiner();
      var rebuildCount = 0;

      await tester.pumpWidget(
        RouteInformationCombinerScope(
          combiner1,
          child: Builder(
            builder: (context) {
              RouteInformationCombiner.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      // Same instance, should not trigger rebuild due to updateShouldNotify
      await tester.pumpWidget(
        RouteInformationCombinerScope(
          combiner1,
          child: Builder(
            builder: (context) {
              RouteInformationCombiner.of(context);
              rebuildCount++;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(rebuildCount, 1);
    });
  });
}
