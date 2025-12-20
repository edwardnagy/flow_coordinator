import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_coordinator/src/identity_route_information_parser.dart';

void main() {
  group('IdentityRouteInformationParser', () {
    late IdentityRouteInformationParser parser;

    setUp(() {
      parser = const IdentityRouteInformationParser();
    });

    test('parseRouteInformation returns same RouteInformation', () async {
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));
      final result = await parser.parseRouteInformation(routeInfo);
      expect(result, same(routeInfo));
    });

    test('parseRouteInformation with complex URI', () async {
      final uri = Uri.parse('/path/to/resource?param1=value1&param2=value2#fragment');
      final routeInfo = RouteInformation(uri: uri, state: {'key': 'value'});
      final result = await parser.parseRouteInformation(routeInfo);
      expect(result, same(routeInfo));
      expect(result.uri, equals(uri));
      expect(result.state, equals({'key': 'value'}));
    });

    test('restoreRouteInformation returns same RouteInformation', () {
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));
      final result = parser.restoreRouteInformation(routeInfo);
      expect(result, same(routeInfo));
    });

    test('restoreRouteInformation with state', () {
      final state = {'data': 'test', 'count': 42};
      final routeInfo = RouteInformation(
        uri: Uri.parse('/restore'),
        state: state,
      );
      final result = parser.restoreRouteInformation(routeInfo);
      expect(result, same(routeInfo));
      expect(result.state, equals(state));
    });

    test('works with empty URI', () async {
      final routeInfo = RouteInformation(uri: Uri());
      final parseResult = await parser.parseRouteInformation(routeInfo);
      expect(parseResult, same(routeInfo));

      final restoreResult = parser.restoreRouteInformation(routeInfo);
      expect(restoreResult, same(routeInfo));
    });

    test('const constructor allows compile-time constant', () {
      const parser1 = IdentityRouteInformationParser();
      const parser2 = IdentityRouteInformationParser();
      expect(parser1, equals(parser2));
    });
  });
}
