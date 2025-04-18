use alloy::primitives::{address, bytes, U256};
use eyre::Result;

mod utils;
use utils::{deploy_signal_service, get_proofs, get_provider};

mod signal_slot;
use signal_slot::{get_signal_slot, NameSpaceConst};

#[tokio::main]
async fn main() -> Result<()> {
    println!();
    println!("🚨🚨🚨");
    println!(
        "PLEASE MAKE SURE YOU HAVE CHANGED THE VALUES OF SENDER, AMOUNT, AND DATA IN THIS FILE"
    );
    println!("OTHERWISE IT MAY NOT MATCH THE DEPOSIT YOU ARE TRYING TO PROVE");
    println!("🚨🚨🚨");
    println!();

    // WARN: CHANGE THESE VALUES AS NEEDED
    let data = bytes!();
    let sender = address!("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
    let amount = U256::from(4000000000000000000_u128);

    let (provider, _anvil) = get_provider()?;

    let signal_service = deploy_signal_service(&provider).await?;

    println!(
        "Deployed signal service at address: {}",
        signal_service.address()
    );

    println!("Sending ETH deposit signal...");
    let builder = signal_service.deposit(sender, data).value(amount);
    let tx = builder.send().await?.get_receipt().await?;

    // Get deposit ID from the transaction receipt logs
    // possibly a better way to do this, but this works :)
    let receipt_logs = tx.logs().get(0).unwrap().topics();
    let deposit_id = receipt_logs.get(1).unwrap();

    let slot = get_signal_slot(deposit_id, &sender, NameSpaceConst::ETHBridge);
    get_proofs(&provider, slot, &signal_service).await?;

    Ok(())
}
