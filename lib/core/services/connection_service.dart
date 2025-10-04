import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _internetSubscription;
  bool _isConnected = true;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  void startMonitoring() {
    // Monitor connectivity changes (WiFi, Mobile, None)
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    // Monitor actual internet connectivity
    _internetSubscription = InternetConnectionChecker()
        .onStatusChange
        .listen(_handleInternetStatusChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      // No network connection
      _updateConnectionStatus(false);
    } else {
      // Has network connection, check if internet is actually available
      _checkInternetConnection();
    }
  }

  void _handleInternetStatusChange(InternetConnectionStatus status) {
    _updateConnectionStatus(status == InternetConnectionStatus.connected);
  }

  Future<void> _checkInternetConnection() async {
    final isConnected = await InternetConnectionChecker().hasConnection;
    _updateConnectionStatus(isConnected);
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(_isConnected);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _connectionController.close();
  }
}
