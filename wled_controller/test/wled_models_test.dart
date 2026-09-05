import 'package:flutter_test/flutter_test.dart';
import 'package:wled_controller/models/wled_models.dart';

void main() {
  group('WledState Model Tests', () {
    test('Correctly parses /json/state payload', () {
      final sampleJson = {
        "on": true,
        "bri": 180,
        "transition": 7,
        "ps": 1,
        "pl": -1,
        "seg": [
          {
            "id": 0,
            "start": 0,
            "stop": 150,
            "len": 150,
            "on": true,
            "bri": 255,
            "col": [
              [255, 160, 0],
              [0, 0, 0],
              [0, 0, 0]
            ],
            "fx": 0,
            "sx": 128,
            "ix": 128,
            "pal": 0,
            "sel": true
          }
        ]
      };

      final state = WledState.fromJson(sampleJson);

      expect(state.on, isTrue);
      expect(state.brightness, equals(180));
      expect(state.transition, equals(7));
      expect(state.currentPreset, equals(1));
      expect(state.segments.length, equals(1));

      final seg = state.segments.first;
      expect(seg.id, equals(0));
      expect(seg.start, equals(0));
      expect(seg.stop, equals(150));
      expect(seg.len, equals(150));
      expect(seg.colors.length, equals(3));
    });

    test('toJson serializes correctly', () {
      final state = WledState(
        on: false,
        brightness: 200,
        transition: 5,
        currentPreset: 2,
        segments: [WledSegment.defaultSegment()],
      );

      final json = state.toJson();

      expect(json['on'], isFalse);
      expect(json['bri'], equals(200));
      expect(json['transition'], equals(5));
      expect(json['ps'], equals(2));
      expect(json['seg'], isNotEmpty);
    });
  });

  group('WledInfo Model Tests', () {
    test('Correctly parses /json/info payload', () {
      final sampleInfoJson = {
        "ver": "0.15.0-b2",
        "vid": 2408150,
        "leds": {
          "count": 150,
          "pwr": 450,
          "fps": 42,
          "maxpwr": 850,
          "maxseg": 32,
          "matrix": {"w": 0, "h": 0}
        },
        "name": "Living Room TV Backlight",
        "udpport": 21324,
        "live": false,
        "arch": "esp32",
        "core": "v3.3.6",
        "freeheap": 184512,
        "uptime": 86400,
        "wifi": {
          "bssid": "AA:BB:CC:DD:EE:FF",
          "signal": 84,
          "channel": 6
        },
        "fs": {"u": 64, "t": 983, "pmt": 1690000000}
      };

      final info = WledInfo.fromJson(sampleInfoJson);

      expect(info.version, equals("0.15.0-b2"));
      expect(info.name, equals("Living Room TV Backlight"));
      expect(info.ledCount, equals(150));
      expect(info.wifiSignal, equals(84));
      expect(info.arch, equals("esp32"));
      expect(info.freeHeap, equals(184512));
      expect(info.uptime, equals(86400));
    });
  });
}
