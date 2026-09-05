import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/wled_models.dart';
import '../services/wled_api_client.dart';
import 'settings_screen.dart';

/// Screen 2: Main Controller (Color, Effects & Segments)
class ControlScreen extends StatefulWidget {
  final WledDevice device;

  const ControlScreen({super.key, required this.device});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with SingleTickerProviderStateMixin {
  late WledApiClient _apiClient;
  late TabController _tabController;

  Color _currentColor = Colors.orange;
  double _speed = 128;
  double _intensity = 128;
  int _selectedEffect = 0;
  String _searchQuery = '';

  List<String> _effects = [
    'Solid',
    'Blink',
    'Breathe',
    'Wipe',
    'Wipe Random',
    'Random Colors',
    'Sweep',
    'Dynamic',
    'Colorloop',
    'Rainbow',
    'Scan',
    'Dual Scan',
    'Fade',
    'Theater',
    'Theater Rainbow',
    'Running',
    'Saw',
    'Twinkle',
    'Dissolve',
    'Dissolve Rnd',
    'Sparkle',
    'Sparkle Dark',
    'Sparkle+',
    'Strobe',
    'Strobe Rainbow',
    'Strobe Mega',
    'Blink Rainbow',
    'Android',
    'Chase',
    'Chase Rainbow',
    'Fire 2012',
    'Fire 2021',
    'Plasma',
    'Aurora',
    'Meteor',
    'Fireworks',
    'Ripple',
  ];

  @override
  void initState() {
    super.initState();
    _apiClient = WledApiClient(ip: widget.device.ip);
    _tabController = TabController(length: 3, vsync: this);

    final seg = widget.device.state?.segments.firstOrNull;
    if (seg != null) {
      if (seg.colors.isNotEmpty) {
        _currentColor = seg.colors.first;
      }
      _speed = seg.effectSpeed.toDouble();
      _intensity = seg.effectIntensity.toDouble();
      _selectedEffect = seg.effectIndex;
    }

    _loadEffects();
  }

  Future<void> _loadEffects() async {
    try {
      final effs = await _apiClient.getEffects();
      if (mounted && effs.isNotEmpty) {
        setState(() => _effects = effs);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filteredEffects = _searchQuery.isEmpty
        ? _effects
        : _effects
            .where((e) => e.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF12131C),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.device.ip,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Device Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(device: widget.device),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.deepPurpleAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.palette_outlined), text: 'Colors'),
            Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Effects'),
            Tab(icon: Icon(Icons.layers_outlined), text: 'Segments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Color Picker & Swatches
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                ColorPicker(
                  pickerColor: _currentColor,
                  onColorChanged: (color) {
                    setState(() => _currentColor = color);
                    _apiClient.setPrimaryColor(0, color);
                  },
                  colorPickerWidth: 280,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                ),
                const SizedBox(height: 24),
                // RGB / Hex summary pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E202E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _currentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RGB(${(_currentColor.r * 255).round()}, ${(_currentColor.g * 255).round()}, ${(_currentColor.b * 255).round()})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick preset color swatches
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    Colors.redAccent,
                    Colors.deepOrange,
                    Colors.amber,
                    Colors.greenAccent,
                    Colors.tealAccent,
                    Colors.cyan,
                    Colors.blueAccent,
                    Colors.purpleAccent,
                    Colors.pinkAccent,
                    Colors.white,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentColor = color);
                        _apiClient.setPrimaryColor(0, color);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor == color ? Colors.white : Colors.white24,
                            width: _currentColor == color ? 3 : 1,
                          ),
                          boxShadow: [
                            if (_currentColor == color)
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Tab 2: Effects Browser & Speed/Intensity sliders
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Speed slider
                    Row(
                      children: [
                        const SizedBox(
                          width: 65,
                          child: Text('Speed', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 0,
                            max: 255,
                            activeColor: Colors.deepPurpleAccent,
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() => _speed = val);
                              _apiClient.setEffect(0, _selectedEffect, speed: val.toInt());
                            },
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text('${_speed.round()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                      ],
                    ),
                    // Intensity slider
                    Row(
                      children: [
                        const SizedBox(
                          width: 65,
                          child: Text('Intensity', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                        Expanded(
                          child: Slider(
                            value: _intensity,
                            min: 0,
                            max: 255,
                            activeColor: Colors.deepPurpleAccent,
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() => _intensity = val);
                              _apiClient.setEffect(0, _selectedEffect, intensity: val.toInt());
                            },
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text('${_intensity.round()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Search bar for effects
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search 180+ effects...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1E202E),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredEffects.length,
                  itemBuilder: (ctx, idx) {
                    final effectName = filteredEffects[idx];
                    final originalIndex = _effects.indexOf(effectName);
                    final isSelected = originalIndex == _selectedEffect;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: Text(
                        effectName,
                        style: TextStyle(
                          color: isSelected ? Colors.deepPurpleAccent : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedEffect = originalIndex);
                        _apiClient.setEffect(
                          0,
                          originalIndex,
                          speed: _speed.toInt(),
                          intensity: _intensity.toInt(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Tab 3: Segments Manager
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ...((widget.device.state?.segments ?? [WledSegment.defaultSegment()]).map((seg) {
                  return Card(
                    color: const Color(0xFF1E202E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: seg.selected ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Segment ${seg.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: seg.on ? Colors.greenAccent.withOpacity(0.2) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  seg.on ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    color: seg.on ? Colors.greenAccent : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LED Range: ${seg.start} to ${seg.stop} (${seg.len} LEDs)',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Brightness: ${(seg.brightness / 2.55).round()}% | Effect: #${seg.effectIndex}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiClient.dispose();
    super.dispose();
  }
}
