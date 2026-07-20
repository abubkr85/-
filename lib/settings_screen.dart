import 'package:flutter/material.dart';
import 'settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsStore.load();
    setState(() {
      _settings = s;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await SettingsStore.save(_settings);
  }

  Future<void> _pickCustomPoint() async {
    final point = await Navigator.push<Offset>(
      context,
      MaterialPageRoute(builder: (_) => const _PointPickerScreen()),
    );
    if (point != null) {
      setState(() {
        _settings.tapPointMode = 'custom';
        _settings.tapX = point.dx;
        _settings.tapY = point.dy;
      });
      await _persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('حساسية اللف يمين/يسار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_settings.turnThreshold.round()}°'),
                  Expanded(
                    child: Slider(
                      min: 8,
                      max: 40,
                      divisions: 32,
                      value: _settings.turnThreshold,
                      onChanged: (v) => setState(() => _settings.turnThreshold = v),
                      onChangeEnd: (_) => _persist(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text('قيمة أقل = استجابة أسرع بحركة أخف', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          const Text('حساسية الرفع/الخفض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_settings.tiltThreshold.round()}°'),
                  Expanded(
                    child: Slider(
                      min: 6,
                      max: 35,
                      divisions: 29,
                      value: _settings.tiltThreshold,
                      onChanged: (v) => setState(() => _settings.tiltThreshold = v),
                      onChangeEnd: (_) => _persist(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('معايرة الاتجاه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('عكس يمين/يسار'),
                  subtitle: const Text('فعّله لو التطبيق يستجيب لليمين وأنت تلف يسار (والعكس)'),
                  value: _settings.invertHorizontal,
                  onChanged: (v) {
                    setState(() => _settings.invertHorizontal = v);
                    _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text('عكس فوق/تحت'),
                  subtitle: const Text('فعّله لو التطبيق يستجيب لفوق وأنت ترفع رأسك لتحت (والعكس)'),
                  value: _settings.invertVertical,
                  onChanged: (v) {
                    setState(() => _settings.invertVertical = v);
                    _persist();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('طول السحب (بكسل)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_settings.dragLength}'),
                  Expanded(
                    child: Slider(
                      min: 50,
                      max: 500,
                      divisions: 45,
                      value: _settings.dragLength.toDouble(),
                      onChanged: (v) => setState(() => _settings.dragLength = v.round()),
                      onChangeEnd: (_) => _persist(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('نقطة الضغط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('وسط الشاشة'),
                  value: 'center',
                  groupValue: _settings.tapPointMode,
                  onChanged: (v) {
                    setState(() => _settings.tapPointMode = v!);
                    _persist();
                  },
                ),
                RadioListTile<String>(
                  title: const Text('نقطة ثابتة محفوظة'),
                  subtitle: _settings.tapPointMode == 'custom' && _settings.tapX != null
                      ? Text('X: ${_settings.tapX!.round()}, Y: ${_settings.tapY!.round()}')
                      : null,
                  value: 'custom',
                  groupValue: _settings.tapPointMode,
                  onChanged: (v) async {
                    if (_settings.tapX == null) {
                      await _pickCustomPoint();
                    } else {
                      setState(() => _settings.tapPointMode = v!);
                      await _persist();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickCustomPoint,
                      icon: const Icon(Icons.touch_app),
                      label: const Text('تحديد نقطة جديدة بالنقر على الشاشة'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointPickerScreen extends StatelessWidget {
  const _PointPickerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('انقر على النقطة المطلوبة')),
      body: GestureDetector(
        onTapUp: (details) {
          Navigator.pop(context, details.globalPosition);
        },
        child: Container(
          color: Colors.black12,
          width: double.infinity,
          height: double.infinity,
          child: const Center(child: Text('انقر في أي مكان لتحديد نقطة الضغط')),
        ),
      ),
    );
  }
}
