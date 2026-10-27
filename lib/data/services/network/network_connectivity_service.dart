import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status.
class NetworkConnectivityService {
  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Checks if the device currently has an active network connection.
  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isAnyConnected(results);
    } catch (_) {
      // Fallback to true so network requests can still be attempted
      return true;
    }
  }

  /// Stream of network connectivity state changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .map(_isAnyConnected)
        .distinct();
  }

  bool _isAnyConnected(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
