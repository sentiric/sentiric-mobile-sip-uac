# 📱 Sentiric Mobile SIP UAC

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![Language](https://img.shields.io/badge/language-Flutter%20%7C%20Rust-blue.svg)]()
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)]()

**Sentiric Mobile SIP UAC**, Sentiric telekom ekosistemi için geliştirilmiş hibrit bir mobil test istemcisidir. Bu uygulama, saha testlerinde gerçek mobil ağ (4G/5G) koşullarını simüle etmek ve uçtan uca sinyal bütünlüğünü doğrulamak için kullanılır.

## 🏗️ Mimari Tasarım: "The Bridge"

Uygulama, performans ve görselliği optimize etmek için hibrit bir mimari kullanır:

1.  **Çekirdek (Core):** SIP sinyalleşme ve deterministik RTP paketleme işlemleri, paylaşılan [sentiric-sip-uac-core](https://github.com/sentiric/sentiric-sip-uac-core) kütüphanesi üzerinden **Rust** ile yönetilir.
2.  **Arayüz (UI):** Hızlı geliştirme ve akıcı kullanıcı deneyimi için **Flutter (Dart)** kullanılır.
3.  **Köprü (FFI):** Rust ve Dart arasındaki iletişim, `flutter_rust_bridge` (v2) teknolojisi ile asenkron ve tip-güvenli (Type-safe) bir şekilde sağlanır.

## 🚀 Hızlı Başlangıç

### Önkoşullar
*   **Flutter SDK:** `^3.0.0`
*   **Rust:** `nightly` veya `stable` toolchain
*   **Android NDK:** Rust kodunu Android için derlemek için gereklidir.
*   **Araçlar:** `cargo install cargo-ndk flutter_rust_bridge_codegen`

### Kurulum ve Çalıştırma

Tüm süreçler `Makefile` üzerinden otomatize edilmiştir:

```bash
# 1. Bağımlılıkları yükle
make setup

# 2. Rust/Dart köprü kodlarını üret
make generate

# 3. Kütüphaneyi Android için derle ve cihazda çalıştır (Cihaz bağlı olmalı)
make deploy-device
```

## 📋 Otomasyon Komutları (Makefile)

| Komut | Açıklama |
| :--- | :--- |
| `make setup` | Gerekli tüm SDK ve Codegen araçlarını sisteme kurar. |
| `make generate` | Rust API'lerini Dart tarafına otomatik olarak bağlar. |
| `make build-android` | Rust çekirdeğini Android (ARM64/v7) için kütüphane olarak derler. |
| `make deploy-device` | Uygulamayı en yüksek performans modunda bağlı cihaza kurar. |

## 🔒 Güvenlik ve İzinler

Uygulama, VoIP operasyonları için aşağıdaki donanımsal izinleri kullanır:
*   `INTERNET`: SIP ve RTP trafiği için.
*   `RECORD_AUDIO`: Mikrofon erişimi (Echo test ve sesli asistan için).
*   `MODIFY_AUDIO_SETTINGS`: Ses çıkış yönetimi.

## 🏛️ Mimari Konum

Bu uygulama, [Sentiric Anayasası](https://github.com/sentiric/sentiric-governance) uyarınca **Telekom Test Katmanı**'nda yer alan "Dış Saha Gözlemcisi" rolündedir.

---
© 2026 Sentiric Team | GNU AGPL-3.0 License
