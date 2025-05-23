use std::env;

use alloy::primitives::{Address, B256};
use eyre::{eyre, Result};

mod signal_slot;
use signal_slot::get_signal_slot;

mod utils;
use utils::{deploy_signal_service, get_proofs, get_provider};

pub fn prompt_sender_and_signal() -> Result<(B256, Address)> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        return Err(eyre!(
            "Must provide both the signal/value and sender address"
        ));
    }

    let signal_str = &args[1];
    let signal: B256 = signal_str
        .parse()
        .map_err(|_| eyre!("Invalid signal format: {}", signal_str))?;

    let sender_str = &args[2];
    let sender: Address = sender_str
        .parse()
        .map_err(|_| eyre!("Invalid sender format: {}", sender_str))?;

    Ok((signal, sender))
}

#[tokio::main]
async fn main() -> Result<()> {
    println!();
    let (signal, sender) = prompt_sender_and_signal()?;

    let (provider, _anvil) = get_provider()?;

    let signal_service = deploy_signal_service(&provider).await?;

    println!(
        "Deployed signal service at address: {}",
        signal_service.address()
    );

    println!("Sending normal signal...");
    let builder = signal_service.sendSignal(signal);
    builder.send().await?.watch().await?;

    let slot = get_signal_slot(&signal, &sender);
    get_proofs(&provider, slot, &signal_service).await?;

    Ok(())
}
