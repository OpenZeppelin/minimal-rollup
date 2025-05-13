
use eyre::Result;

mod signal_slot;
use signal_slot::get_signal_slot;

mod utils;
use utils::{deploy_signal_service, get_proofs, get_provider};

use alloy::primitives::Bytes;
use std::fs;


fn expand_vector(vec: Vec<Bytes>, name: &str) -> String {
    let mut expanded = String::new();
    for (i, item) in vec.iter().enumerate() {
        expanded += format!("\n\t\t{}[{}] = hex\"{}\";", name, i, item).replace("0x","").as_str();
    }
    return expanded;
}

#[tokio::main]
async fn main() -> Result<()> {
    let (provider, _anvil, signer) = get_provider()?;
    let signal_service = deploy_signal_service(&provider).await?;
    
    // keccak256("arbitrary_signal");
    let signal =  "0x404204dbc47bf04b49cf2fa2c69cf230c5bfcce81985444f7375c24620c37e88".parse()?;
    signal_service.sendSignal(signal).send().await?.watch().await?;
    let slot = get_signal_slot(&signal, &signer.address());
    let proof   = get_proofs(&provider, slot, &signal_service).await?;

    
    let template = fs::read_to_string("offchain/sample_proof.tmpl")?;
    let formatted = template.replace("{signal_service_address}", signal_service.address().to_string().as_str())
        .replace("{block_hash}", proof.block_hash.to_string().as_str())
        .replace("{state_root}", proof.state_root.to_string().as_str())
        .replace("{account_proof_size}", proof.account_proof.len().to_string().as_str())
        .replace("{storage_proof_size}", proof.storage_proof.len().to_string().as_str())
        .replace("{populate_account_proof}", &expand_vector(proof.account_proof, "signalProof.accountProof"))
        .replace("{populate_storage_proof}", &expand_vector(proof.storage_proof, "signalProof.storageProof"))
        .replace("{sender}", signer.address().to_string().as_str())
        .replace("{value}", signal.to_string().as_str())
        .replace("{slot}", proof.slot.to_string().as_str());
    println!("{}", formatted);
    Ok(())
}