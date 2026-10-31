import 'package:connectivity_plus/connectivity_plus.dart';

/// What the app needs to know about the network. An interface so a test can
/// answer without the plugin.
abstract interface class ConnectivityChecker {
  Future<bool> isOnline();
}

/// Tells whether the phone has a network connection.
class ConnectivityService implements ConnectivityChecker {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  /// Emits true when the connection comes back and false when it is lost.
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
