import 'package:flutter/widgets.dart';

extension RouteInformationUtils on RouteInformation {
  /// Determines whether this route matches the given [pattern].
  ///
  /// A match occurs if:
  /// - The path segments in [pattern] appear in this URI in the same order.
  /// - All query parameters in [pattern] are present and match those in this
  /// URI.
  /// - The fragment in [pattern] is either empty or matches this URI's
  /// fragment.
  /// - The state matches the pattern’s state, using [stateMatcher] if provided.
  ///   If omitted, states are considered equal if they are identical.
  bool matchesUrlPattern(
    RouteInformation pattern, {
    bool Function(Object? state, Object? patternState)? stateMatcher,
  }) {
    final isPathMatching =
        pattern.uri.pathSegments.length <= uri.pathSegments.length &&
            pattern.uri.pathSegments.asMap().entries.every(
                  (patternEntry) =>
                      patternEntry.value == uri.pathSegments[patternEntry.key],
                );
    final isQueryMatching = pattern.uri.queryParameters.entries.every(
      (patternEntry) =>
          uri.queryParameters[patternEntry.key] == patternEntry.value,
    );
    final isFragmentMatching =
        pattern.uri.fragment.isEmpty || pattern.uri.fragment == uri.fragment;
    final isStateMatching = stateMatcher?.call(state, pattern.state) ??
        (pattern.state == null || state == pattern.state);

    return isPathMatching &&
        isQueryMatching &&
        isFragmentMatching &&
        isStateMatching;
  }
}
