import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
