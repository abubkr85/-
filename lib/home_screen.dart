import 'package:flutter/material.dart';
import 'native_bridge.dart';
import 'settings_screen.dart';
import 'settings_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isRunning = false;
  bool _cameraGranted = false;
  bool _accessibilityEnabled = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    final cam = await NativeBridge.isCameraPermissionGranted();
    final acc = await NativeBridge.isAccessibilityServiceEnabled();
    final running = await NativeBridge.isServiceRunning();
    setState(() {
      _cameraGranted = cam;
      _accessibilityEnabled = acc;
      _isRunning = running;
      _checking = false;
    });
  }

  Future<void> _onPowerPressed() async {
    if (_isRunning) {
      await NativeBridge.stopGestureService();
      await _refreshStatus();
      return;
    }

    if (!_cameraGranted) {
      final granted = await NativeBridge.requestCameraPermission();
      if (!granted) {
        _showMessage('يجب منح صلاحية الكاميرا حتى يعمل التطبيق.');
        await _refreshStatus();
        return;
      }
    }

    final accEnabled = await NativeBridge.isAccessibilityServiceEnabled();
    if (!accEnabled) {
      _showMessage('فعّل خدمة "التحكم بالرأس" من صفحة الإعدادات التي ستفتح الآن.');
      await NativeBridge.openAccessibilitySettings();
      return;
    }

    final settings = await SettingsStore.load();
    await NativeBridge.updateSettings(
      dragLength: settings.dragLength,
      tapPointMode: settings.tapPointMode,
      tapX: settings.tapX,
      tapY: settings.tapY,
      turnThreshold: settings.turnThreshold,
      tiltThreshold: settings.tiltThreshold,
      invertHorizontal: settings.invertHorizontal,
      invertVertical: settings.invertVertical,
    );
    await NativeBridge.startGestureService();
    await _refreshStatus();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحكم بإيماءات الرأس'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (_isRunning) {
                final settings = await SettingsStore.load();
                await NativeBridge.updateSettings(
                  dragLength: settings.dragLength,
                  tapPointMode: settings.tapPointMode,
                  tapX: settings.tapX,
                  tapY: settings.tapY,
                  turnThreshold: settings.turnThreshold,
                  tiltThreshold: settings.tiltThreshold,
                  invertHorizontal: settings.invertHorizontal,
                  invertVertical: settings.invertVertical,
                );
              }
            },
          ),
        ],
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: _onPowerPressed,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRunning
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.12),
                          border: Border.all(
                            color: _isRunning ? Colors.green : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.power_settings_new,
                          size: 64,
                          color: _isRunning ? Colors.green : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _isRunning ? 'يعمل الآن — يراقب إيماءات الرأس' : 'متوقف',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _statusTile('صلاحية الكاميرا', _cameraGranted),
                  _statusTile('خدمة Accessibility مفعّلة', _accessibilityEnabled),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'الإيماءات المدعومة:\n'
                        '↔ لف الرأس يمين/يسار\n'
                        '↕ رفع/خفض الرأس\n'
                        '👁 غمزة عين واحدة = اضغط\n\n'
                        'يمكنك ضبط الحساسية من شاشة الإعدادات.',
                        style: TextStyle(height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statusTile(String title, bool ok) {
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? Colors.green : Colors.redAccent,
      ),
      title: Text(title),
    );
  }
}
