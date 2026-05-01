import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/utils/logger.dart';

/// Connection state for P2P connections
class ConnectionState {
  final Device? connectedPeer;
  final bool isConnecting;
  final String? lastError;
  final DateTime? connectedAt;

  const ConnectionState({
    this.connectedPeer,
    this.isConnecting = false,
    this.lastError,
    this.connectedAt,
  });

  ConnectionState copyWith({
    Device? connectedPeer,
    bool? isConnecting,
    String? lastError,
    DateTime? connectedAt,
  }) {
    return ConnectionState(
      connectedPeer: connectedPeer ?? this.connectedPeer,
      isConnecting: isConnecting ?? this.isConnecting,
      lastError: lastError ?? this.lastError,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  bool get isConnected => connectedPeer != null;
}

/// Notifier for managing P2P connection state
class ConnectionStateNotifier extends StateNotifier<ConnectionState> {
  ConnectionStateNotifier() : super(const ConnectionState());

  /// Called when a peer connects
  void onPeerConnected(Device device) {
    AppLogger.info('🔗 Connection state: Peer connected - ${device.name}');
    state = ConnectionState(
      connectedPeer: device,
      isConnecting: false,
      connectedAt: DateTime.now(),
    );
  }

  /// Called when a peer disconnects
  void onPeerDisconnected() {
    if (state.connectedPeer != null) {
      AppLogger.info('🔌 Connection state: Peer disconnected - ${state.connectedPeer!.name}');
    }
    state = const ConnectionState();
  }

  /// Called when connection attempt starts
  void onConnectionStart() {
    AppLogger.info('🔄 Connection state: Connection attempt started');
    state = state.copyWith(isConnecting: true, lastError: null);
  }

  /// Called when connection fails
  void onConnectionError(String error) {
    AppLogger.info('❌ Connection state: Connection failed - $error');
    state = state.copyWith(
      isConnecting: false,
      lastError: error,
    );
  }

  /// Clear any error state
  void clearError() {
    if (state.lastError != null) {
      AppLogger.info('✅ Connection state: Error cleared');
      state = state.copyWith(lastError: null);
    }
  }
}

/// Provider for connection state
final connectionStateProvider = StateNotifierProvider<ConnectionStateNotifier, ConnectionState>(
  (ref) => ConnectionStateNotifier(),
);
