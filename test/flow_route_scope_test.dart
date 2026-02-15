import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteInformationMatcher', () {
    test('matches exact same URI', () {
      final info = RouteInformation(uri: Uri.parse('/home'));
      final pattern = RouteInformation(uri: Uri.parse('/home'));
      expect(info.matchesUrlPattern(pattern), isTrue);
    });

    test('matches when pattern is prefix of path', () {
      final info = RouteInformation(uri: Uri.parse('/home/details'));
      final pattern = RouteInformation(uri: Uri.parse('/home'));
      expect(info.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when path segments differ', () {
      final info = RouteInformation(uri: Uri.parse('/other'));
      final pattern = RouteInformation(uri: Uri.parse('/home'));
      expect(info.matchesUrlPattern(pattern), isFalse);
    });

    test(
      'does not match when pattern has more path segments',
      () {
        final info = RouteInformation(uri: Uri.parse('/home'));
        final pattern = RouteInformation(uri: Uri.parse('/home/details'));
        expect(info.matchesUrlPattern(pattern), isFalse);
      },
    );

    test('matches when query parameters match', () {
      final info = RouteInformation(
        uri: Uri.parse('/home?tab=books&view=list'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home?tab=books'),
      );
      expect(info.matchesUrlPattern(pattern), isTrue);
    });

    test(
      'does not match when query parameter value differs',
      () {
        final info = RouteInformation(
          uri: Uri.parse('/home?tab=books'),
        );
        final pattern = RouteInformation(
          uri: Uri.parse('/home?tab=movies'),
        );
        expect(info.matchesUrlPattern(pattern), isFalse);
      },
    );

    test(
      'does not match when query parameter is missing',
      () {
        final info = RouteInformation(uri: Uri.parse('/home'));
        final pattern = RouteInformation(
          uri: Uri.parse('/home?tab=books'),
        );
        expect(info.matchesUrlPattern(pattern), isFalse);
      },
    );

    test('matches when fragment matches', () {
      final info = RouteInformation(
        uri: Uri.parse('/home#section'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home#section'),
      );
      expect(info.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when fragment differs', () {
      final info = RouteInformation(
        uri: Uri.parse('/home#section1'),
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home#section2'),
      );
      expect(info.matchesUrlPattern(pattern), isFalse);
    });

    test(
      'matches any fragment when pattern fragment is empty',
      () {
        final info = RouteInformation(
          uri: Uri.parse('/home#section'),
        );
        final pattern = RouteInformation(uri: Uri.parse('/home'));
        expect(info.matchesUrlPattern(pattern), isTrue);
      },
    );

    test(
      'matches when pattern state is null regardless of state',
      () {
        final info = RouteInformation(
          uri: Uri.parse('/home'),
          state: 'someState',
        );
        final pattern = RouteInformation(uri: Uri.parse('/home'));
        expect(info.matchesUrlPattern(pattern), isTrue);
      },
    );

    test('matches when states are identical', () {
      final info = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'state',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'state',
      );
      expect(info.matchesUrlPattern(pattern), isTrue);
    });

    test('does not match when states differ', () {
      final info = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'stateA',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'stateB',
      );
      expect(info.matchesUrlPattern(pattern), isFalse);
    });

    test('uses custom stateMatcher when provided', () {
      final info = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'any',
      );
      final pattern = RouteInformation(
        uri: Uri.parse('/home'),
        state: 'different',
      );
      expect(
        info.matchesUrlPattern(
          pattern,
          stateMatcher: (_, __) => true,
        ),
        isTrue,
      );
    });

    test(
      'custom stateMatcher returning false prevents match',
      () {
        final info = RouteInformation(
          uri: Uri.parse('/home'),
          state: 'same',
        );
        final pattern = RouteInformation(
          uri: Uri.parse('/home'),
          state: 'same',
        );
        expect(
          info.matchesUrlPattern(
            pattern,
            stateMatcher: (_, __) => false,
          ),
          isFalse,
        );
      },
    );
  });

  group('FlowRouteScope widget tests', () {
    testWidgets(
      'sets isTopRoute correctly inside a MaterialPage',
      (tester) async {
        bool? isTopRoute;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              pages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/home'),
                    ),
                    child: Builder(
                      builder: (context) {
                        final scope = FlowRouteStatusScope.maybeOf(context);
                        isTopRoute = scope?.isTopRoute;
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(isTopRoute, isTrue);
      },
    );

    testWidgets(
      'sets isActive to false when isActive property is false',
      (tester) async {
        bool? isActive;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              pages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/home'),
                    ),
                    isActive: false,
                    child: Builder(
                      builder: (context) {
                        final scope = FlowRouteStatusScope.maybeOf(context);
                        isActive = scope?.isActive;
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(isActive, isFalse);
      },
    );

    testWidgets(
      'isTopRoute is false for non-top pages',
      (tester) async {
        bool? firstPageIsTopRoute;
        bool? secondPageIsTopRoute;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              pages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/first'),
                    ),
                    child: Builder(
                      builder: (context) {
                        final scope = FlowRouteStatusScope.maybeOf(context);
                        firstPageIsTopRoute = scope?.isTopRoute;
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/second'),
                    ),
                    child: Builder(
                      builder: (context) {
                        final scope = FlowRouteStatusScope.maybeOf(context);
                        secondPageIsTopRoute = scope?.isTopRoute;
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(firstPageIsTopRoute, isFalse);
        expect(secondPageIsTopRoute, isTrue);
      },
    );
  });
}

// Minimal flow coordinator for widget tests.
class _TestFlowCoordinator extends StatefulWidget {
  const _TestFlowCoordinator({required this.pages});

  final List<Page> pages;

  @override
  State<_TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<_TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => widget.pages;

  @override
  Widget build(BuildContext context) => flowRouter(context);
}

Widget _buildTestApp({
  required WidgetBuilder homeBuilder,
}) {
  return WidgetsApp.router(
    routerConfig: FlowCoordinatorRouter(
      homeBuilder: homeBuilder,
    ),
    color: const Color(0xFF000000),
  );
}
