import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flux/models/file_metadata.dart';

/// Provider for transfer history
final transferHistoryProvider = StateNotifierProvider<TransferHistoryNotifier, List<TransferHistory>>((ref) {
  return TransferHistoryNotifier();
});

/// Notifier for managing transfer history
class TransferHistoryNotifier extends StateNotifier<List<TransferHistory>> {
  static const String _storageKey = 'transfer_history';
  static const int _maxHistoryItems = 100;

  TransferHistoryNotifier() : super([]) {
    _loadHistory();
  }

  /// Load transfer history from SharedPreferences
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        final history = decoded
            .map((item) => TransferHistory.fromJson(item as Map<String, dynamic>))
            .toList();
        state = history;
      }
    } catch (e) {
      // If loading fails, start with empty history
      state = [];
    }
  }

  /// Save transfer history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, historyJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Add a new transfer to history
  void addTransfer(TransferHistory transfer) {
    state = [transfer, ...state];
    
    // Keep only the most recent transfers
    if (state.length > _maxHistoryItems) {
      state = state.sublist(0, _maxHistoryItems);
    }
    
    _saveHistory();
  }

  /// Clear all transfer history
  void clearHistory() {
    state = [];
    _saveHistory();
  }

  /// Get transfers by direction
  List<TransferHistory> getTransfersByDirection(TransferDirection direction) {
    return state.where((transfer) => transfer.direction == direction).toList();
  }
}
