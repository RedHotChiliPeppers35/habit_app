import 'package:flutter/widgets.dart';

/// Global navigator key used by the app so widgets above the [MaterialApp]
/// can still push routes using the app's Navigator.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
