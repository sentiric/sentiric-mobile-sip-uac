// sentiric-sip-mobile-uac/lib/main.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentiric_sip_mobile_uac/src/rust/api/simple.dart';
import 'package:sentiric_sip_mobile_uac/src/rust/frb_generated.dart';
import 'package:sentiric_sip_mobile_uac/telecom_telemetry.dart';
import 'dart:io';
import 'dart:ffi';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Platform.isAndroid) {
      try {
        DynamicLibrary.open('libc++_shared.so');
      } catch (e) {
        debugPrint("⚠️ libc++ load warning: $e");
      }
    }
    await RustLib.init();
    await initLogger(); 
  } catch (e) {
    debugPrint("Rust Init Error: $e");
  }
  runApp(const SentiricApp());
}

class SentiricApp extends StatelessWidget {
  const SentiricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentiric Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF00FF9D),
      ),
      home: const DialerScreen(),
    );
  }
}

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});
  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController(text: "34.122.40.122");
  final TextEditingController _portController = TextEditingController(text: "5060");
  final TextEditingController _toController = TextEditingController(text: "9999");
  final TextEditingController _fromController = TextEditingController(text: "mobile-tester");

  final List<TelemetryEntry> _telemetryLogs = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isCalling = false;
  bool _isMediaActive = false;
  int _rxPackets = 0;
  int _txPackets = 0;

  void _processEvent(String raw) {
    if (!mounted) return;
    final entry = TelecomTelemetry.parse(raw);

    setState(() {
      if (entry.level == TelemetryLevel.media && entry.rxCount != null) {
        _rxPackets = entry.rxCount!;
        _txPackets = entry.txCount!;
      } else if (raw == "MediaActive") {
        _isMediaActive = true;
      } else {
        if (!raw.contains("RtpStats")) {
           _telemetryLogs.add(entry);
        }
      }
    });

    // Auto-scroll logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startCall() async {
    if (await Permission.microphone.request().isGranted) {
      setState(() {
        _telemetryLogs.clear();
        _isCalling = true;
        _isMediaActive = false;
        _rxPackets = 0;
        _txPackets = 0;
      });

      final stream = startSipCall(
        targetIp: _ipController.text.trim(),
        targetPort: int.parse(_portController.text.trim()),
        toUser: _toController.text.trim(),
        fromUser: _fromController.text.trim(),
      );

      stream.listen(
        (event) => _processEvent(event),
        onDone: () => setState(() => _isCalling = false),
        onError: (e) => _processEvent("Error(\"System: $e\")"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 SENTIRIC FIELD MONITOR', style: TextStyle(fontSize: 14, letterSpacing: 1)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildConfigurationPanel(),
          if (_isCalling) _buildLiveStatusCard(),
          const SizedBox(height: 10),
          Expanded(child: _buildLogConsole()),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.03),
      child: Column(
        children: [
          Row(children: [
            Expanded(flex: 3, child: _smallField(_ipController, "Edge IP")),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: _smallField(_portController, "Port")),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _smallField(_toController, "To")),
            const SizedBox(width: 8),
            Expanded(child: _smallField(_fromController, "From")),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isCalling ? null : _startCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCalling ? Colors.blueGrey : const Color(0xFF00FF9D),
                foregroundColor: Colors.black,
              ),
              child: Text(_isCalling ? "TELECOM SESSION ACTIVE" : "INITIATE SIP CALL"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      enabled: !_isCalling,
      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _isMediaActive ? const Color(0xFF00FF9D) : Colors.orangeAccent, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusItem("SIP", "CONNECTED", Colors.blue),
          _statusItem("RTP", _isMediaActive ? "ACTIVE" : "LATCHING...", _isMediaActive ? const Color(0xFF00FF9D) : Colors.orangeAccent),
          _statusItem("PKTS", "RX:$_rxPackets TX:$_txPackets", Colors.white70),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildLogConsole() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _telemetryLogs.length,
        itemBuilder: (context, index) {
          final entry = _telemetryLogs[index];
          return _logLine(entry);
        },
      ),
    );
  }

  Widget _logLine(TelemetryEntry entry) {
    Color color = Colors.white70;
    if (entry.level == TelemetryLevel.status) color = const Color(0xFF00FF9D);
    if (entry.level == TelemetryLevel.error) color = Colors.redAccent;
    if (entry.level == TelemetryLevel.sip) color = Colors.cyanAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Text(
        entry.message,
        style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: color),
      ),
    );
  }
}