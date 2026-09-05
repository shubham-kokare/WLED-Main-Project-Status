import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Network and WebSocket client for interacting with a WLED hardware controller.
class WledApiClient {
  final String ip;
  final Dio _dio;
  WebSocketChannel? _wsChannel;

  WledApiClient({required this.ip})
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://$ip',
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  /// Fetch full state, info, effects, and palettes (/json)
  Future<Map<String, dynamic>> getFullData() async {
    final response = await _dio.get('/json');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {};
  }

  /// Fetch lighting effects list (/json/eff)
  Future<List<String>> getEffects() async {
    final response = await _dio.get('/json/eff');
    if (response.data is List) {
      return (response.data as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Fetch color palettes list (/json/pal)
  Future<List<String>> getPalettes() async {
    final response = await _dio.get('/json/pal');
    if (response.data is List) {
      return (response.data as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Push partial or full state update (/json/state)
  Future<void> updateState(Map<String, dynamic> stateDelta) async {
    await _dio.post('/json/state', data: stateDelta);
  }

  /// Toggle master power
  Future<void> togglePower(bool currentOn) async {
    await updateState({'on': !currentOn});
  }

  /// Set master brightness (0 - 255)
  Future<void> setBrightness(int bri) async {
    await updateState({'bri': bri.clamp(0, 255)});
  }

  /// Set segment primary color
  Future<void> setPrimaryColor(int segmentId, Color color) async {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    await updateState({
      'seg': [
        {
          'id': segmentId,
          'col': [
            [r, g, b]
          ]
        }
      ]
    });
  }

  /// Set segment effect with optional speed and intensity
  Future<void> setEffect(
    int segmentId,
    int fxIndex, {
    int? speed,
    int? intensity,
  }) async {
    final Map<String, dynamic> segData = {
      'id': segmentId,
      'fx': fxIndex,
    };
    if (speed != null) segData['sx'] = speed.clamp(0, 255);
    if (intensity != null) segData['ix'] = intensity.clamp(0, 255);

    await updateState({
      'seg': [segData]
    });
  }

  /// Set segment color palette
  Future<void> setPalette(int segmentId, int paletteIndex) async {
    await updateState({
      'seg': [
        {'id': segmentId, 'pal': paletteIndex}
      ]
    });
  }

  /// Trigger a software reboot on the ESP32/ESP8266 controller
  Future<void> reboot() async {
    await updateState({'rb': true});
  }

  /// Establish persistent WebSocket connection for real-time live events (/ws)
  Stream<dynamic> connectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = WebSocketChannel.connect(Uri.parse('ws://$ip/ws'));
    return _wsChannel!.stream;
  }

  /// Dispose open resources
  void dispose() {
    _wsChannel?.sink.close();
    _dio.close();
  }
}
