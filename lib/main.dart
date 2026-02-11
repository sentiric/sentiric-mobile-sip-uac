import 'package:flutter/material.dart';
import 'package:sentiric_mobile_sip_uac/src/rust/api/simple.dart';
import 'package:sentiric_mobile_sip_uac/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Rust kütüphanesini başlat
  await RustLib.init();
  // 2. Logger'ı başlat (Android logcat bağlantısı için)
  await initLogger(); 
  runApp(const SentiricApp());
}

class SentiricApp extends StatelessWidget {
  const SentiricApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.green,
      ),
      home: const DialerScreen(),
    );
  }
}

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});
  @override
  _DialerScreenState createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  final TextEditingController _ipController = TextEditingController(text: "34.122.40.122");
  final List<String> _logs = [];
  bool _isCalling = false;
  final ScrollController _scrollController = ScrollController();

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleCall() {
    setState(() {
      _logs.clear();
      _isCalling = true;
    });

    try {
      // DÜZELTME: 'await' kaldırıldı (Stream direkt döner) 
      // DÜZELTME: 'from_user' -> 'fromUser' yapıldı (Dart standardı)
      final stream = startSipCall(
        targetIp: _ipController.text,
        targetPort: 5060,
        toUser: "9999",
        fromUser: "mobile-tester", 
      );

      stream.listen(
        (event) {
          _addLog(event);
          if (event == "FINISH") setState(() => _isCalling = false);
        },
        onError: (e) => _addLog("❌ Error: $e"),
        onDone: () => setState(() => _isCalling = false),
      );
    } catch (e) {
      _addLog("🔥 Critical: $e");
      setState(() => _isCalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📡 Sentiric SIP Monitor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(labelText: 'SBC Endpoint IP'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isCalling ? null : _handleCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text(_isCalling ? "CALL IN PROGRESS..." : "DIAL ECHO TEST (9999)"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _logs[index].contains("ERROR") ? Colors.red : Colors.greenAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}