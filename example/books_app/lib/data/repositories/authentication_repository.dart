import 'dart:async';

class AuthenticationRepository {
  factory AuthenticationRepository() {
    assert(
      _instance == null,
      'AuthenticationRepository is a singleton and has already been instantiated. '
      'Use AuthenticationRepository.instance to access the instance.',
    );
    return _instance = AuthenticationRepository._internal();
  }

  AuthenticationRepository._internal() {
    // Emit initial state.
    _authenticationStateController.add(_isAuthenticated);
  }

  static AuthenticationRepository get instance => _instance!;
  static AuthenticationRepository? _instance;

  var _isAuthenticated = false;
  final _authenticationStateController = StreamController<bool>.broadcast();

  /// Stream that emits the current authentication state.
  Stream<bool> get authenticationStateStream =>
      _authenticationStateController.stream;

  /// Get the current authentication state synchronously.
  bool get isAuthenticated => _isAuthenticated;

  void login({
    required String username,
    required String password,
  }) {
    _isAuthenticated = true;
    _authenticationStateController.add(_isAuthenticated);
  }

  void logout() {
    _isAuthenticated = false;
    _authenticationStateController.add(_isAuthenticated);
  }

  void dispose() {
    _authenticationStateController.close();
    _instance = null;
  }
}
