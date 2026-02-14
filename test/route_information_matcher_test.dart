import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationMatcher', () {
    test('matches when states are equal', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path'),
        state: 'state-value',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path'),
        state: 'state-value',
      );

      expect(routeInfo.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when states differ', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path'),
        state: 'state-a',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path'),
        state: 'state-b',
      );

      expect(routeInfo.matchesUrlPattern(pattern), isFalse);
    });

    test('matches when pattern state is null', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path'),
        state: 'any-state',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path'),
        // state is null
      );

      expect(routeInfo.matchesUrlPattern(pattern), isTrue);
    });

    test('matches when both states are null', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path'),
      );

      expect(routeInfo.matchesUrlPattern(pattern), isTrue);
    });

    test('matches with query parameters', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path?a=1&b=2'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path?a=1'),
      );

      expect(routeInfo.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when query parameter differs', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path?a=1'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path?a=2'),
      );

      expect(routeInfo.matchesUrlPattern(pattern), isFalse);
    });

    test('matches with custom state matcher', () {
      final routeInfo = RouteInformation(
        uri: Uri.parse('/path'),
        state: {'key': 'value'},
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/path'),
        state: {'key': 'value'},
      );

      expect(
        routeInfo.matchesUrlPattern(
          pattern,
          stateMatcher: (state, patternState) {
            if (state is Map && patternState is Map) {
              return state['key'] == patternState['key'];
            }
            return false;
          },
        ),
        isTrue,
      );
    });
  });
}
