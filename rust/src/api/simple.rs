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
    let (tx, mut rx) = mpsc::channel::<UacEvent>(100);
    let client = UacClient::new(tx);

    // Olayları Flutter'a ve Logcat'e yönlendir
    tokio::spawn(async move {
        while let Some(event) = rx.recv().await {
            let msg = match event {
                UacEvent::Log(m) => format!("[LOG] {}", m),
                UacEvent::Status(s) => format!("STATUS: {}", s),
                UacEvent::Error(e) => format!("ERROR: {}", e),
                UacEvent::CallEnded => "FINISH".to_string(),
            };
            info!("{}", msg); // Android Logcat'e basar
            let _ = sink.add(msg); // Flutter UI'a gönderir
        }
    });

    // Çağrıyı başlat
    client.start_call(target_ip, target_port, to_user, from_user).await?;
    
    Ok(())
}