import 'dart:async';

import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/repositories/authentication_repository.dart';
import '../screens/login_screen.dart';
import 'home_flow_coordinator.dart';

class RootFlowCoordinator extends StatefulWidget {
  const RootFlowCoordinator({super.key});

  @override
  State<RootFlowCoordinator> createState() => _RootFlowCoordinatorState();
}

class _RootFlowCoordinatorState extends State<RootFlowCoordinator>
    with FlowCoordinatorMixin<RootFlowCoordinator> {
  final _authRepository = AuthenticationRepository();
  StreamSubscription<bool>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Handle the initial authentication state.
    _onAuthenticationStateChanged(
      isAuthenticated: _authRepository.isAuthenticated,
    );
    // Handle changes to the authentication state.
    _authSubscription = _authRepository.authenticationStateStream.listen(
      (isAuthenticated) {
        _onAuthenticationStateChanged(isAuthenticated: isAuthenticated);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authRepository.dispose();
    super.dispose();
  }

  void _onAuthenticationStateChanged({required bool isAuthenticated}) {
    if (isAuthenticated) {
      flowNavigator.setPages([_Pages.homePage()]);
    } else {
      flowNavigator.setPages([_Pages.loginPage()]);
    }
  }

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    final RouteInformation? childRouteInformation;
    if (!_authRepository.isAuthenticated) {
      // Redirect to login.
      flowNavigator.setPages([_Pages.loginPage()]);
      childRouteInformation = null;
    } else {
      // Redirect to home.
      flowNavigator.setPages([_Pages.homePage()]);
      if (routeInformation.uri.pathSegments.firstOrNull == 'login') {
        childRouteInformation = RouteInformation(uri: Uri(path: ''));
      } else {
        childRouteInformation = routeInformation;
      }
    }
    return SynchronousFuture(childRouteInformation);
  }
}

class _Pages {
  static Page loginPage() => MaterialPage(
        key: const ValueKey('loginPage'),
        child: FlowRouteScope(
          routeInformation: RouteInformation(uri: Uri(path: 'login')),
          child: const LoginScreen(),
        ),
      );

  static Page homePage() => MaterialPage(
        key: const ValueKey('homePage'),
        child: FlowRouteScope(
          routeInformation: RouteInformation(uri: Uri(path: '')),
          child: const HomeFlowCoordinator(),
        ),
      );
}
