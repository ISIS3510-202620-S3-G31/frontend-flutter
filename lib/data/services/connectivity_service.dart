import 'package:connectivity_plus/connectivity_plus.dart';

/// Tells whether the phone has a network connection.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  /// Emits true when the connection comes back and false when it is lost.
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
