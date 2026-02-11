use sentiric_sip_uac_core::{UacClient, UacEvent};
use tokio::sync::mpsc;

pub async fn start_sip_call(
    target_ip: String,
    target_port: u16,
    to_user: String,
    from_user: String,
) -> String {
    let (tx, mut rx) = mpsc::channel::<UacEvent>(100);
    let client = UacClient::new(tx);

    tokio::spawn(async move {
        while let Some(event) = rx.recv().await {
            println!("Core Event: {:?}", event);
        }
    });

    match client.start_call(target_ip, target_port, to_user, from_user).await {
        Ok(_) => "Call Finished".to_string(),
        Err(e) => format!("Error: {}", e),
    }
}