import 'package:flutter/material.dart';
import 'package:sentiric_mobile_sip_uac/src/rust/api/simple.dart'; // Üretilen API yolu
import 'package:sentiric_mobile_sip_uac/src/rust/frb_generated.dart'; // Üretilen Init yolu

Future<void> main() async {
  // 1. Rust Kütüphanesini Başlat (V2 Standardı)
  await RustLib.init();
  runApp(const SentiricApp());
}

class SentiricApp extends StatelessWidget {
  const SentiricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
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
  String _status = "Ready";
  bool _isCalling = false;

  Future<void> _handleCall() async {
    setState(() {
      _isCalling = true;
      _status = "Call Initializing...";
    });

    try {
      // 2. Rust Fonksiyonunu Çağır (V2 artık direkt async döner)
      final result = await startSipCall(
        targetIp: _ipController.text,
        targetPort: 5060,
        toUser: "9999",
        fromUser: "mobile-tester",
      );
      
      setState(() {
        _status = result;
        _isCalling = false;
      });
    } catch (e) {
      setState(() {
        _status = "Error: $e";
        _isCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sentiric Mobile UAC v2')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_input_antenna, size: 80, color: Colors.green),
            const SizedBox(height: 30),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Edge Server IP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text("Status: $_status", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isCalling ? null : _handleCall,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isCalling 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("START ECHO TEST", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}