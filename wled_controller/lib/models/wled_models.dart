import 'package:flutter/material.dart';

/// Represents a single WLED hardware device on the network.
class WledDevice {
  final String id;
  final String ip;
  final String name;
  final bool isOnline;
  final WledState? state;
  final WledInfo? info;

  const WledDevice({
    required this.id,
    required this.ip,
    required this.name,
    this.isOnline = true,
    this.state,
    this.info,
  });

  WledDevice copyWith({
    String? name,
    bool? isOnline,
    WledState? state,
    WledInfo? info,
  }) {
    return WledDevice(
      id: id,
      ip: ip,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      state: state ?? this.state,
      info: info ?? this.info,
    );
  }
}

/// Represents the active lighting state of a WLED controller (/json/state).
class WledState {
  final bool on;
  final int brightness; // 0 - 255
  final int transition; // In 100ms units
  final int currentPreset;
  final List<WledSegment> segments;

  const WledState({
    required this.on,
    required this.brightness,
    this.transition = 7,
    this.currentPreset = -1,
    required this.segments,
  });

  factory WledState.fromJson(Map<String, dynamic> json) {
    final rawSegs = json['seg'] as List? ?? [];
    List<WledSegment> segs = rawSegs
        .whereType<Map<String, dynamic>>()
        .map((s) => WledSegment.fromJson(s))
        .toList();

    if (segs.isEmpty) {
      segs.add(WledSegment.defaultSegment());
    }

    return WledState(
      on: json['on'] as bool? ?? true,
      brightness: (json['bri'] as num?)?.toInt() ?? 128,
      transition: (json['transition'] as num?)?.toInt() ?? 7,
      currentPreset: (json['ps'] as num?)?.toInt() ?? -1,
      segments: segs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'bri': brightness,
      'transition': transition,
      'ps': currentPreset,
      'seg': segments.map((s) => s.toJson()).toList(),
    };
  }

  WledState copyWith({
    bool? on,
    int? brightness,
    int? transition,
    int? currentPreset,
    List<WledSegment>? segments,
  }) {
    return WledState(
      on: on ?? this.on,
      brightness: brightness ?? this.brightness,
      transition: transition ?? this.transition,
      currentPreset: currentPreset ?? this.currentPreset,
      segments: segments ?? this.segments,
    );
  }
}

/// Represents a configured LED segment in WLED.
class WledSegment {
  final int id;
  final int start;
  final int stop;
  final int len;
  final bool on;
  final int brightness;
  final List<Color> colors;
  final int effectIndex;
  final int effectSpeed;
  final int effectIntensity;
  final int paletteIndex;
  final bool selected;

  const WledSegment({
    required this.id,
    required this.start,
    required this.stop,
    required this.len,
    required this.on,
    required this.brightness,
    required this.colors,
    required this.effectIndex,
    required this.effectSpeed,
    required this.effectIntensity,
    required this.paletteIndex,
    required this.selected,
  });

  factory WledSegment.defaultSegment() {
    return const WledSegment(
      id: 0,
      start: 0,
      stop: 30,
      len: 30,
      on: true,
      brightness: 255,
      colors: [Colors.orange, Colors.black, Colors.black],
      effectIndex: 0,
      effectSpeed: 128,
      effectIntensity: 128,
      paletteIndex: 0,
      selected: true,
    );
  }

  factory WledSegment.fromJson(Map<String, dynamic> json) {
    List<Color> parsedColors = [];
    if (json['col'] != null && json['col'] is List) {
      for (var colEntry in json['col']) {
        if (colEntry is List && colEntry.length >= 3) {
          parsedColors.add(Color.fromARGB(
            255,
            (colEntry[0] as num).toInt(),
            (colEntry[1] as num).toInt(),
            (colEntry[2] as num).toInt(),
          ));
        }
      }
    }
    if (parsedColors.isEmpty) {
      parsedColors.add(Colors.white);
    }

    final startVal = (json['start'] as num?)?.toInt() ?? 0;
    final stopVal = (json['stop'] as num?)?.toInt() ?? 30;
    final lenVal = (json['len'] as num?)?.toInt() ?? (stopVal - startVal).abs();

    return WledSegment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      start: startVal,
      stop: stopVal,
      len: lenVal > 0 ? lenVal : 30,
      on: json['on'] as bool? ?? true,
      brightness: (json['bri'] as num?)?.toInt() ?? 255,
      colors: parsedColors,
      effectIndex: (json['fx'] as num?)?.toInt() ?? 0,
      effectSpeed: (json['sx'] as num?)?.toInt() ?? 128,
      effectIntensity: (json['ix'] as num?)?.toInt() ?? 128,
      paletteIndex: (json['pal'] as num?)?.toInt() ?? 0,
      selected: json['sel'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start,
      'stop': stop,
      'len': len,
      'on': on,
      'bri': brightness,
      'fx': effectIndex,
      'sx': effectSpeed,
      'ix': effectIntensity,
      'pal': paletteIndex,
      'sel': selected,
      'col': colors
          .map((c) => [
                (c.a * 255).round() == 0 ? 0 : (c.r * 255).round(),
                (c.g * 255).round(),
                (c.b * 255).round(),
              ])
          .toList(),
    };
  }

  WledSegment copyWith({
    bool? on,
    int? brightness,
    List<Color>? colors,
    int? effectIndex,
    int? effectSpeed,
    int? effectIntensity,
    int? paletteIndex,
    bool? selected,
  }) {
    return WledSegment(
      id: id,
      start: start,
      stop: stop,
      len: len,
      on: on ?? this.on,
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      effectIndex: effectIndex ?? this.effectIndex,
      effectSpeed: effectSpeed ?? this.effectSpeed,
      effectIntensity: effectIntensity ?? this.effectIntensity,
      paletteIndex: paletteIndex ?? this.paletteIndex,
      selected: selected ?? this.selected,
    );
  }
}

/// Represents hardware, Wi-Fi, and system info from /json/info.
class WledInfo {
  final String version;
  final String name;
  final int ledCount;
  final int wifiSignal;
  final String arch;
  final int freeHeap;
  final int uptime;

  const WledInfo({
    required this.version,
    required this.name,
    required this.ledCount,
    required this.wifiSignal,
    required this.arch,
    required this.freeHeap,
    required this.uptime,
  });

  factory WledInfo.fromJson(Map<String, dynamic> json) {
    return WledInfo(
      version: json['ver'] as String? ?? 'Unknown',
      name: json['name'] as String? ?? 'WLED Controller',
      ledCount: (json['leds']?['count'] as num?)?.toInt() ?? 0,
      wifiSignal: (json['wifi']?['signal'] as num?)?.toInt() ?? 0,
      arch: json['arch'] as String? ?? 'ESP32',
      freeHeap: (json['freeheap'] as num?)?.toInt() ?? 0,
      uptime: (json['uptime'] as num?)?.toInt() ?? 0,
    );
  }
}
