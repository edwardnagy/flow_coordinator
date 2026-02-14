import 'package:flow_coordinator/src/identity_route_information_parser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityRouteInformationParser', () {
    const parser = IdentityRouteInformationParser();

    test('parseRouteInformation returns same route information', () async {
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));
      final result = await parser.parseRouteInformation(routeInfo);
      expect(result, routeInfo);
    });

    test('restoreRouteInformation returns same route information', () {
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));
      expect(parser.restoreRouteInformation(routeInfo), routeInfo);
    });
  });
}
