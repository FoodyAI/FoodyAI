import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _internetSubscription;
  bool _isConnected = true;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  void startMonitoring() {
    print('🌐 ConnectionService: Starting network monitoring...');

    // Check initial connection status
    _checkInitialConnection();

    // Monitor connectivity changes (WiFi, Mobile, None)
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    print('🌐 ConnectionService: Subscribed to connectivity changes');

    // Monitor actual internet connectivity
    _internetSubscription = InternetConnectionChecker()
        .onStatusChange
        .listen(_handleInternetStatusChange);
    print('🌐 ConnectionService: Subscribed to internet status changes');
  }

  Future<void> _checkInitialConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      print('🌐 ConnectionService: Initial connectivity = $connectivityResult');

      if (connectivityResult == ConnectivityResult.none) {
        _updateConnectionStatus(false);
      } else {
        final hasInternet = await InternetConnectionChecker().hasConnection;
        print('🌐 ConnectionService: Initial internet check = $hasInternet');
        _updateConnectionStatus(hasInternet);
      }
    } catch (e) {
      print('❌ ConnectionService: Error checking initial connection: $e');
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    print('🌐 ConnectionService: Connectivity changed to: $result');

    if (result == ConnectivityResult.none) {
      // No network connection
      print('📵 ConnectionService: No network connection');
      _updateConnectionStatus(false);
    } else {
      // Has network connection, check if internet is actually available
      print('📶 ConnectionService: Network available, checking internet...');
      _checkInternetConnection();
    }
  }

  void _handleInternetStatusChange(InternetConnectionStatus status) {
    print('🌐 ConnectionService: Internet status changed to: $status');
    _updateConnectionStatus(status == InternetConnectionStatus.connected);
  }

  Future<void> _checkInternetConnection() async {
    try {
      final isConnected = await InternetConnectionChecker().hasConnection;
      print('🌐 ConnectionService: Internet check result = $isConnected');
      _updateConnectionStatus(isConnected);
    } catch (e) {
      print('❌ ConnectionService: Error checking internet: $e');
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    print(
        '🌐 ConnectionService: Status update - Old: $_isConnected, New: $isConnected');

    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(_isConnected);
      print(
          '✅ ConnectionService: Status CHANGED! Emitted to stream: $isConnected');
    } else {
      print('ℹ️ ConnectionService: Status unchanged, no emission');
    }
  }

  void dispose() {
    print('🌐 ConnectionService: Disposing...');
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _connectionController.close();
  }
}
