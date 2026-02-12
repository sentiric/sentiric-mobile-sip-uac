// sentiric-mobile-sip-uac/rust/src/api/simple.rs
use sentiric_sip_uac_core::{UacClient, UacEvent};
use tokio::sync::mpsc;
use crate::frb_generated::StreamSink;
use log::{info, LevelFilter};
use android_logger::Config;

/// Uygulama ilk açıldığında Rust loglarını Android sistemine bağlar.
pub fn init_logger() {
    android_logger::init_once(
        Config::default()
            .with_max_level(LevelFilter::Debug)
            .with_tag("SENTIRIC-RUST"),
    );
    info!("✅ Rust Logger initialized for Android.");
}

/// SIP çağrısını başlatır ve olayları anlık olarak stream eder.
pub async fn start_sip_call(
    target_ip: String,
    target_port: u16,
    to_user: String,
    from_user: String,
    sink: StreamSink<String>, // FRB v2 Stream yapısı
) -> anyhow::Result<()> {
    // 1. Kanalları oluştur
    let (tx, mut rx) = mpsc::channel::<UacEvent>(100);
    
    // 2. Client'ı oluştur
    let client = UacClient::new(tx);

    // 3. Olayları dinle, formatla ve Flutter'a gönder
    tokio::spawn(async move {
        while let Some(event) = rx.recv().await {
            let msg = match event {
                UacEvent::Log(m) => format!("[LOG] {}", m),
                UacEvent::Status(s) => format!("STATUS: {}", s),
                UacEvent::Error(e) => format!("ERROR: {}", e),
                UacEvent::CallEnded => "FINISH".to_string(),
            };
            
            // a) Android Logcat'e bas (IDE'den izlemek için)
            info!("{}", msg); 
            
            // b) Flutter UI'a gönder (Ekranda görmek için)
            // Hata alırsak (UI kapanmışsa) döngüden çık
            if sink.add(msg).is_err() {
                break;
            }
        }
    });

    // 4. Çağrıyı başlat
    client.start_call(target_ip, target_port, to_user, from_user).await?;
    
    Ok(())
}