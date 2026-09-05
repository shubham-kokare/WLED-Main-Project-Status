import 'package:flutter/material.dart';
import '../models/wled_models.dart';
import '../services/wled_api_client.dart';

/// Screen 4: Hardware & Device Settings Screen
class SettingsScreen extends StatelessWidget {
  final WledDevice device;

  const SettingsScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final info = device.info;
    final client = WledApiClient(ip: device.ip);

    return Scaffold(
      backgroundColor: const Color(0xFF12131C),
      appBar: AppBar(
        title: const Text('Device Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('Hardware Information'),
          _buildInfoTile('Device Name', info?.name ?? device.name),
          _buildInfoTile('IP Address', device.ip),
          _buildInfoTile('Firmware Version', info?.version ?? 'Unknown'),
          _buildInfoTile('Architecture', info?.arch.toUpperCase() ?? 'ESP32'),
          _buildInfoTile('Total LED Count', '${info?.ledCount ?? 0} LEDs'),
          _buildInfoTile('Wi-Fi Signal', '${info?.wifiSignal ?? 0}%'),
          _buildInfoTile(
            'Free Heap Memory',
            info != null ? '${((info.freeHeap) / 1024).round()} KB' : 'N/A',
          ),
          _buildInfoTile(
            'Uptime',
            info != null
                ? '${((info.uptime) / 3600).toStringAsFixed(1)} hours'
                : 'N/A',
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Device Management'),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 0.8),
              ),
            ),
            icon: const Icon(Icons.restart_alt),
            label: const Text(
              'Reboot Controller',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E202E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Reboot WLED?', style: TextStyle(color: Colors.white)),
                  content: Text(
                    'Are you sure you want to reboot ${device.name} (${device.ip})?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Reboot', style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await client.reboot();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reboot command dispatched to controller.'),
                      backgroundColor: Color(0xFF1E202E),
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.deepPurpleAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E202E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
