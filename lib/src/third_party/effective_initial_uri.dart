import 'package:flutter/widgets.dart';

// This function is derived from the go_router package (License: BSD-3-Clause).
// Source: https://github.com/flutter/packages/blob/6e2acf7b62e5ea04d7c658bfe7804526cd1b533a/packages/go_router/lib/src/router.dart#L542-L568
Uri effectiveInitialUri({
  required bool overridePlatformDefaultLocation,
  required Uri? initialUri,
}) {
  if (overridePlatformDefaultLocation) {
    // initialUri must not be null as asserted in the constructor.
    return initialUri!;
  }

  var platformDefaultUri = Uri.parse(
    WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  if (platformDefaultUri.hasEmptyPath) {
    platformDefaultUri = Uri(
      path: '/',
      queryParameters: platformDefaultUri.queryParameters,
    );
  }

  if (initialUri == null) {
    return platformDefaultUri;
  } else if (platformDefaultUri == Uri.parse('/')) {
    return initialUri;
  } else {
    return platformDefaultUri;
  }
}
