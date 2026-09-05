import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wled_models.dart';
import '../providers/wled_providers.dart';
import 'control_screen.dart';

/// Screen 1: Home / Device Discovery Dashboard
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final onlineCount = devices.where((d) => d.isOnline).length;

    return Scaffold(
      backgroundColor: const Color(0xFF12131C),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WLED Studio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 20,
              ),
            ),
            Text(
              devices.isEmpty
                  ? 'No devices configured'
                  : '$onlineCount of ${devices.length} online',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (devices.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              color: const Color(0xFF1E202E),
              onSelected: (action) {
                if (action == 'all_on') {
                  ref.read(deviceListProvider.notifier).toggleAllPower(true);
                } else if (action == 'all_off') {
                  ref.read(deviceListProvider.notifier).toggleAllPower(false);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'all_on',
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.greenAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Turn All On', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'all_off',
                  child: Row(
                    children: [
                      Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Turn All Off', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Refresh devices',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(deviceListProvider.notifier).refreshAll();
            },
          ),
          IconButton(
            tooltip: 'Add device by IP',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDeviceDialog(context, ref),
          ),
        ],
      ),
      body: devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hub_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No WLED devices found',
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your controller by IP address.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                    onPressed: () => _showAddDeviceDialog(context, ref),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return _DeviceCard(device: device);
              },
            ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, WidgetRef ref) {
    final ipController = TextEditingController();
    final nameController = TextEditingController(text: 'WLED Light');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E202E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add WLED Device', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'IP Address (e.g. 192.168.1.150)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (ipController.text.trim().isNotEmpty) {
                ref.read(deviceListProvider.notifier).addDevice(
                      ipController.text.trim(),
                      nameController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  final WledDevice device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = device.state;
    final isOn = state?.on ?? false;
    final bri = state?.brightness ?? 128;
    final firstSeg = state?.segments.isNotEmpty == true ? state!.segments.first : null;
    final primaryColor = (firstSeg?.colors.isNotEmpty == true) ? firstSeg!.colors.first : Colors.orange;

    return Card(
      color: const Color(0xFF1E202E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOn ? primaryColor.withOpacity(0.5) : Colors.white10,
          width: isOn ? 1.5 : 1.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: device.isOnline ? Colors.greenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.ip,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          if (device.info?.wifiSignal != null && device.isOnline) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.wifi, color: Colors.white38, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${device.info!.wifiSignal}%',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOn,
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (val) {
                    ref.read(deviceListProvider.notifier).toggleDevicePower(device.ip);
                  },
                ),
              ],
            ),
            if (isOn) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.brightness_6, color: Colors.white54, size: 20),
                  Expanded(
                    child: Slider(
                      value: bri.toDouble(),
                      min: 0,
                      max: 255,
                      activeColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white12,
                      onChanged: (val) {
                        ref
                            .read(deviceListProvider.notifier)
                            .setDeviceBrightness(device.ip, val.toInt());
                      },
                    ),
                  ),
                  Text(
                    '${(bri / 2.55).round()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Remove Device',
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                  onPressed: () {
                    ref.read(deviceListProvider.notifier).removeDevice(device.ip);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.tune, size: 18, color: Colors.deepPurpleAccent),
                  label: const Text(
                    'Open Controls',
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ControlScreen(device: device),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
