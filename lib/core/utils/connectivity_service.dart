// lib/core/utils/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<ConnectivityResult> get connectivityResult async {
    final results = await _connectivity.checkConnectivity();
    // Return the primary connectivity result
    if (results.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
    if (results.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
    if (results.contains(ConnectivityResult.ethernet)) return ConnectivityResult.ethernet;
    if (results.contains(ConnectivityResult.vpn)) return ConnectivityResult.vpn;
    if (results.contains(ConnectivityResult.other)) return ConnectivityResult.other;
    return ConnectivityResult.none;
  }

  Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
      // Convert List<ConnectivityResult> to single ConnectivityResult
      if (results.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
      if (results.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
      if (results.contains(ConnectivityResult.ethernet)) return ConnectivityResult.ethernet;
      if (results.contains(ConnectivityResult.vpn)) return ConnectivityResult.vpn;
      if (results.contains(ConnectivityResult.other)) return ConnectivityResult.other;
      return ConnectivityResult.none;
    });
  }
}