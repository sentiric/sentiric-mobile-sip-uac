// sentiric-sip-mobile-uac/lib/telecom_telemetry.dart

enum TelemetryLevel { info, status, error, sip, media }

class TelemetryEntry {
  final String message;
  final TelemetryLevel level;
  final bool isSipPacket;
  final int? rxCount;
  final int? txCount;

  TelemetryEntry({
    required this.message,
    this.level = TelemetryLevel.info,
    this.isSipPacket = false,
    this.rxCount,
    this.txCount,
  });
}

class TelecomTelemetry {
  /// Rust SDK'dan gelen ham string çıktılarını analiz eder.
  static TelemetryEntry parse(String raw) {
    // 1. MediaActive Olayı (Ses akışı teyidi)
    if (raw == "MediaActive") {
      return TelemetryEntry(
        message: "🎙️ AUDIO STREAM VERIFIED",
        level: TelemetryLevel.status,
      );
    }

    // 2. RtpStats Olayı (rx_cnt: 10, tx_cnt: 12)
    if (raw.contains("RtpStats")) {
      final rxMatch = RegExp(r"rx_cnt: (\d+)").firstMatch(raw);
      final txMatch = RegExp(r"tx_cnt: (\d+)").firstMatch(raw);
      
      final rx = int.tryParse(rxMatch?.group(1) ?? "0");
      final tx = int.tryParse(txMatch?.group(1) ?? "0");

      return TelemetryEntry(
        message: "Network Stats Update",
        level: TelemetryLevel.media,
        rxCount: rx,
        txCount: tx,
      );
    }

    // 3. Durum Değişiklikleri: CallStateChanged(Connected)
    if (raw.startsWith("CallStateChanged(")) {
      final state = raw.substring(17, raw.length - 1);
      return TelemetryEntry(
        message: "🔔 SIP: $state",
        level: TelemetryLevel.status,
      );
    }

    // 4. Hatalar: Error("...")
    if (raw.startsWith("Error(\"")) {
      final err = raw.substring(7, raw.length - 2);
      return TelemetryEntry(
        message: "❌ ERROR: $err",
        level: TelemetryLevel.error,
      );
    }

    // 5. Standart Loglar ve SIP Dökümleri: Log("...")
    if (raw.startsWith("Log(\"")) {
      String content = raw.substring(5, raw.length - 2);
      content = content.replaceAll("\\n", "\n").replaceAll("\\\"", "\"").replaceAll("\\r", "");

      bool isSip = content.contains("SIP/2.0") || 
                   content.contains("INVITE") || 
                   content.contains("ACK");

      return TelemetryEntry(
        message: content,
        level: isSip ? TelemetryLevel.sip : TelemetryLevel.info,
        isSipPacket: isSip,
      );
    }

    return TelemetryEntry(message: raw);
  }
}