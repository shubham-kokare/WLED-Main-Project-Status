# WLED Studio (Flutter Native Client)

A cross-platform native Flutter controller for WLED devices running on ESP32/ESP8266 microcontrollers.

## Architecture

- **State Management**: [Riverpod 2.x](https://riverpod.dev) (`StateNotifierProvider`)
- **Networking**: [Dio](https://pub.dev/packages/dio) for HTTP JSON REST API (`/json`, `/json/state`, `/json/info`) & [WebSocketChannel](https://pub.dev/packages/web_socket_channel) for live events (`ws://<ip>/ws`)
- **Persistence**: [shared_preferences](https://pub.dev/packages/shared_preferences) for caching discovered devices
- **Color Engine**: [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) for HSV color wheel & quick palettes

## Project Structure

```
wled_controller/
├── lib/
│   ├── main.dart                # App entrypoint (Material 3 Dark Theme)
│   ├── models/
│   │   └── wled_models.dart     # WledDevice, WledState, WledSegment, WledInfo
│   ├── services/
│   │   └── wled_api_client.dart # Dio REST client and WebSocketChannel
│   ├── providers/
│   │   └── wled_providers.dart  # Riverpod device list and optimistic update state
│   └── screens/
│       ├── home_screen.dart     # Multi-device dashboard & power/brightness toggles
│       ├── control_screen.dart  # Color wheel, Effects browser, Segments tab
│       └── settings_screen.dart # Hardware telemetry and reboot trigger
├── test/
│   └── wled_models_test.dart    # Model serialization and deserialization unit tests
└── pubspec.yaml
```

## How to Run

1. Make sure Flutter is installed and added to your PATH:
   ```bash
   flutter doctor
   ```
2. Navigate to `wled_controller`:
   ```bash
   cd wled_controller
   flutter pub get
   ```
3. Run the app on your preferred target (Windows desktop, Chrome web, Android, iOS):
   ```bash
   flutter run
   ```
4. Enter your WLED controller's IP address (e.g., `192.168.1.150`).
