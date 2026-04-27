import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flux/utils/logger.dart';

/// Windows-native network service using Win32 APIs
/// Provides accurate network detection on Windows platform
class WindowsNetworkService {
  static final WindowsNetworkService _instance = WindowsNetworkService._internal();
  factory WindowsNetworkService() => _instance;
  WindowsNetworkService._internal();

  /// Check if Windows is connected to any network
  bool isNetworkAvailable() {
    try {
      // Check if any network adapter is up
      final adapters = _getNetworkAdapters();
      return adapters.any((adapter) => 
        adapter.isUp && 
        !adapter.isLoopback && 
        adapter.hasIPAddress
      );
    } catch (e) {
      AppLogger.error('Failed to check Windows network', e);
      return false;
    }
  }

  /// Get all network adapters
  List<_NetworkAdapter> _getNetworkAdapters() {
    final adapters = <_NetworkAdapter>[];
    
    try {
      // Use ipconfig /all to get network info
      final result = Process.runSync('ipconfig', ['/all']);
      final output = result.stdout as String;
      
      // Parse adapters from ipconfig output
      final lines = output.split('\n');
      _NetworkAdapter? currentAdapter;
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        // New adapter section
        if (trimmed.endsWith(':') && !trimmed.startsWith(' ')) {
          if (currentAdapter != null) {
            adapters.add(currentAdapter);
          }
          currentAdapter = _NetworkAdapter(name: trimmed.replaceAll(':', ''));
        }
        
        // IP Address
        if (trimmed.contains('IPv4 Address')) {
          final match = RegExp(r'IPv4 Address[^:]*:\s*([\d.]+)').firstMatch(trimmed);
          if (match != null && currentAdapter != null) {
            currentAdapter.ipAddress = match.group(1);
          }
        }
        
        // Subnet Mask
        if (trimmed.contains('Subnet Mask')) {
          final match = RegExp(r'Subnet Mask[^:]*:\s*([\d.]+)').firstMatch(trimmed);
          if (match != null && currentAdapter != null) {
            currentAdapter.subnetMask = match.group(1);
          }
        }
        
        // Default Gateway
        if (trimmed.contains('Default Gateway')) {
          final match = RegExp(r'Default Gateway[^:]*:\s*([\d.]+)').firstMatch(trimmed);
          if (match != null && currentAdapter != null) {
            currentAdapter.gateway = match.group(1);
          }
        }
        
        // Physical Address (MAC)
        if (trimmed.contains('Physical Address')) {
          final match = RegExp(r'Physical Address[^:]*:\s*([\w-]+)').firstMatch(trimmed);
          if (match != null && currentAdapter != null) {
            currentAdapter.macAddress = match.group(1);
          }
        }
      }
      
      if (currentAdapter != null) {
        adapters.add(currentAdapter);
      }
      
    } catch (e) {
      AppLogger.error('Failed to get network adapters', e);
    }
    
    return adapters;
  }

  /// Get the primary local IP address
  Future<String?> getLocalIP() async {
    try {
      final adapters = _getNetworkAdapters();
      
      // Find the first adapter with a valid IP that's not loopback
      for (final adapter in adapters) {
        if (adapter.ipAddress != null && 
            adapter.ipAddress != '127.0.0.1' &&
            !adapter.name.toLowerCase().contains('loopback') &&
            !adapter.name.toLowerCase().contains('virtual')) {
          return adapter.ipAddress;
        }
      }
      
      // Fallback: use NetworkInterface
      return await _getIPFromNetworkInterface();
    } catch (e) {
      AppLogger.error('Failed to get local IP', e);
      return null;
    }
  }

  /// Fallback method using Dart NetworkInterface
  Future<String?> _getIPFromNetworkInterface() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      for (final interface in interfaces) {
        // Skip virtual/tunnel adapters
        if (interface.name.toLowerCase().contains('virtual') ||
            interface.name.toLowerCase().contains('tunnel') ||
            interface.name.toLowerCase().contains('vpn')) {
          continue;
        }
        
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Prefer 192.168.x.x, 10.x.x.x, or 172.x.x.x
          if (ip.startsWith('192.168.') || 
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            return ip;
          }
        }
      }
      
      // Return first available if no preferred found
      for (final interface in interfaces) {
        if (interface.addresses.isNotEmpty) {
          return interface.addresses.first.address;
        }
      }
    } catch (e) {
      AppLogger.error('NetworkInterface fallback failed', e);
    }
    return null;
  }

  /// Get WiFi SSID on Windows
  /// Uses netsh command
  String? getWifiSSID() {
    try {
      final result = Process.runSync('netsh', ['wlan', 'show', 'interfaces']);
      final output = result.stdout as String;
      
      final match = RegExp(r'SSID\s*:\s*(.+)').firstMatch(output);
      if (match != null) {
        return match.group(1)?.trim();
      }
    } catch (e) {
      AppLogger.error('Failed to get WiFi SSID', e);
    }
    return null;
  }

  /// Check if connected to WiFi
  bool isWifiConnected() {
    try {
      final result = Process.runSync('netsh', ['wlan', 'show', 'interfaces']);
      final output = result.stdout as String;
      
      // Check if there's a connected interface
      return output.contains('State') && output.contains('connected');
    } catch (e) {
      return false;
    }
  }

  /// Check if connected to Ethernet
  bool isEthernetConnected() {
    try {
      final adapters = _getNetworkAdapters();
      return adapters.any((adapter) => 
        adapter.name.toLowerCase().contains('ethernet') &&
        adapter.ipAddress != null
      );
    } catch (e) {
      return false;
    }
  }

  /// Get all available network info
  Future<Map<String, dynamic>> getNetworkInfo() async {
    return {
      'isAvailable': isNetworkAvailable(),
      'ipAddress': await getLocalIP(),
      'wifiSSID': getWifiSSID(),
      'isWifi': isWifiConnected(),
      'isEthernet': isEthernetConnected(),
    };
  }

  /// Get network adapter info for logging
  void logNetworkAdapters() {
    final adapters = _getNetworkAdapters();
    for (final adapter in adapters) {
      AppLogger.info('Network Adapter: ${adapter.name}');
      AppLogger.info('  IP: ${adapter.ipAddress}');
      AppLogger.info('  Gateway: ${adapter.gateway}');
      AppLogger.info('  MAC: ${adapter.macAddress}');
    }
  }
}

class _NetworkAdapter {
  final String name;
  String? ipAddress;
  String? subnetMask;
  String? gateway;
  String? macAddress;
  bool isUp = true;
  bool isLoopback = false;
  
  bool get hasIPAddress => ipAddress != null && ipAddress!.isNotEmpty;
  
  _NetworkAdapter({required this.name}) {
    isLoopback = name.toLowerCase().contains('loopback');
  }
}
