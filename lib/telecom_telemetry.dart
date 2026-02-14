// lib/telecom_telemetry.dart

enum TelemetryLevel { info, status, error, sip, media }

class TelemetryEntry {
  final String message;
  final TelemetryLevel level;
  final bool isSipPacket;
  
  // İstatistiksel veriler (Varsa)
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
  /// Rust SDK'dan gelen olay string'lerini (Debug format) parse eder.
  static TelemetryEntry parse(String raw) {
    
    // 1. MEDYA AKIŞI BAŞLADI (Latching Success)
    if (raw.contains("MediaActive")) {
      return TelemetryEntry(
        message: "🎙️ AUDIO PATH ESTABLISHED (2-WAY)",
        level: TelemetryLevel.status,
      );
    }

    // 2. İSTATİSTİKLER (RtpStats)
    // Rust Formatı: RtpStats { rx_cnt: 123, tx_cnt: 456 }
    if (raw.contains("RtpStats")) {
      final rxMatch = RegExp(r"rx_cnt:\s*(\d+)").firstMatch(raw);
      final txMatch = RegExp(r"tx_cnt:\s*(\d+)").firstMatch(raw);
      
      final rx = int.tryParse(rxMatch?.group(1) ?? "0");
      final tx = int.tryParse(txMatch?.group(1) ?? "0");

      return TelemetryEntry(
        message: "Stats Update", // Bu mesaj UI'da log olarak gösterilmeyecek, sadece sayaçları güncelleyecek
        level: TelemetryLevel.media,
        rxCount: rx,
        txCount: tx,
      );
    }

    // 3. SIP DURUM DEĞİŞİMİ
    // Rust Formatı: CallStateChanged(Connected)
    if (raw.contains("CallStateChanged")) {
      // Parantez içini al
      final state = raw.split('(').last.split(')').first;
      return TelemetryEntry(
        message: "🔔 SIP STATE: $state",
        level: TelemetryLevel.status,
      );
    }

    // 4. HATALAR
    if (raw.contains("Error") || raw.contains("Fail")) {
      // Temizleme: Error("...") formatından tırnakları ve sarmalayıcıyı at
      String clean = raw.replaceAll("Error(", "").replaceAll(")", "").replaceAll("\"", "");
      return TelemetryEntry(
        message: "❌ ERROR: $clean",
        level: TelemetryLevel.error,
      );
    }

    // 5. STANDART LOGLAR ve SIP PAKETLERİ
    if (raw.contains("Log(")) {
      // Log("...") içeriğini çıkar
      String content = raw;
      int start = raw.indexOf("Log(\"");
      if (start != -1) {
        content = raw.substring(start + 5, raw.lastIndexOf("\""));
      }
      
      // Kaçış karakterlerini düzelt (Rust debug formatından gelen \n'ler)
      content = content.replaceAll("\\n", "\n").replaceAll("\\r", "").replaceAll("\\\"", "\"");

      bool isSip = content.contains("SIP/2.0") || 
                   content.contains("INVITE") || 
                   content.contains("ACK") ||
                   content.contains("BYE");

      return TelemetryEntry(
        message: content,
        level: isSip ? TelemetryLevel.sip : TelemetryLevel.info,
        isSipPacket: isSip,
      );
    }

    // Tanınmayan format (Fallback)
    return TelemetryEntry(message: raw);
  }
}