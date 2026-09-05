import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wled_models.dart';
import '../services/wled_api_client.dart';

/// Notifier managing configured WLED devices, discovery, and live states.
class DeviceListNotifier extends StateNotifier<List<WledDevice>> {
  static const String _storageKey = 'wled_saved_devices';

  DeviceListNotifier() : super([]) {
    _loadSavedDevices();
  }

  /// Load devices from SharedPreferences, or populate demo default if empty
  Future<void> _loadSavedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_storageKey);

      if (savedList != null && savedList.isNotEmpty) {
        state = savedList.map((entry) {
          final map = jsonDecode(entry) as Map<String, dynamic>;
          return WledDevice(
            id: map['ip'] ?? '',
            ip: map['ip'] ?? '',
            name: map['name'] ?? 'WLED Light',
          );
        }).toList();
      } else {
        // Default initial device
        state = [
          const WledDevice(
            id: '192.168.1.150',
            ip: '192.168.1.150',
            name: 'Living Room Strip',
          ),
        ];
      }
    } catch (_) {
      state = [
        const WledDevice(
          id: '192.168.1.150',
          ip: '192.168.1.150',
          name: 'Living Room Strip',
        ),
      ];
    }

    // Probe initial devices
    for (final device in state) {
      fetchDeviceStatus(device.ip);
    }
  }

  Future<void> _saveDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = state.map((d) => jsonEncode({'ip': d.ip, 'name': d.name})).toList();
      await prefs.setStringList(_storageKey, entries);
    } catch (_) {}
  }

  /// Add a new device by IP and custom name
  void addDevice(String ip, String name) {
    if (state.any((d) => d.ip == ip)) return;

    final device = WledDevice(
      id: ip,
      ip: ip,
      name: name.isNotEmpty ? name : 'WLED Light',
    );
    state = [...state, device];
    _saveDevices();
    fetchDeviceStatus(ip);
  }

  /// Remove device by IP
  void removeDevice(String ip) {
    state = state.where((d) => d.ip != ip).toList();
    _saveDevices();
  }

  /// Fetch full status and info for a specific device
  Future<void> fetchDeviceStatus(String ip) async {
    try {
      final client = WledApiClient(ip: ip);
      final data = await client.getFullData();
      final wledState = data['state'] != null
          ? WledState.fromJson(Map<String, dynamic>.from(data['state'] as Map))
          : null;
      final wledInfo = data['info'] != null
          ? WledInfo.fromJson(Map<String, dynamic>.from(data['info'] as Map))
          : null;

      state = state.map((d) {
        if (d.ip == ip) {
          return d.copyWith(
            state: wledState,
            info: wledInfo,
            name: (wledInfo?.name.isNotEmpty ?? false) ? wledInfo!.name : d.name,
            isOnline: true,
          );
        }
        return d;
      }).toList();
    } catch (_) {
      state = state.map((d) {
        if (d.ip == ip) return d.copyWith(isOnline: false);
        return d;
      }).toList();
    }
  }

  /// Toggle master power with optimistic UI update
  Future<void> toggleDevicePower(String ip) async {
    final index = state.indexWhere((d) => d.ip == ip);
    if (index == -1) return;

    final device = state[index];
    final currentOn = device.state?.on ?? false;
    final newOn = !currentOn;

    // Optimistic UI update
    state = [
      for (final d in state)
        if (d.ip == ip && d.state != null)
          d.copyWith(state: d.state!.copyWith(on: newOn))
        else
          d
    ];

    try {
      final client = WledApiClient(ip: ip);
      await client.togglePower(currentOn);
    } catch (_) {
      // Rollback on failure
      state = [
        for (final d in state)
          if (d.ip == ip && d.state != null)
            d.copyWith(state: d.state!.copyWith(on: currentOn))
          else
            d
      ];
    }
  }

  /// Update master brightness with optimistic UI update
  Future<void> setDeviceBrightness(String ip, int bri) async {
    final clampedBri = bri.clamp(0, 255);

    state = [
      for (final d in state)
        if (d.ip == ip && d.state != null)
          d.copyWith(state: d.state!.copyWith(brightness: clampedBri))
        else
          d
    ];

    try {
      final client = WledApiClient(ip: ip);
      await client.setBrightness(clampedBri);
    } catch (_) {}
  }

  /// Master switch: Turn all online devices On or Off
  Future<void> toggleAllPower(bool turnOn) async {
    state = [
      for (final d in state)
        if (d.state != null)
          d.copyWith(state: d.state!.copyWith(on: turnOn))
        else
          d
    ];

    for (final d in state) {
      try {
        final client = WledApiClient(ip: d.ip);
        await client.updateState({'on': turnOn});
      } catch (_) {}
    }
  }

  /// Refresh all configured devices
  Future<void> refreshAll() async {
    for (final device in state) {
      await fetchDeviceStatus(device.ip);
    }
  }
}

/// Global device list provider
final deviceListProvider =
    StateNotifierProvider<DeviceListNotifier, List<WledDevice>>((ref) {
  return DeviceListNotifier();
});
