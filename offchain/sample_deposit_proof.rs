
use eyre::Result;

mod signal_slot;
use signal_slot::get_signal_slot;

mod utils;
use utils::{deploy_signal_service, deploy_eth_bridge, get_proofs, get_provider};

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
    let eth_bridge = deploy_eth_bridge(&provider, *signal_service.address()).await?;
    
    // This is an address on the destination chain, so it seems natural to use one generated there
    // In this case, the CrossChainDepositExists.sol test case defines _randomAddress("recipient");
    let recipient= "0x99A270Be1AA5E97633177041859aEEB9a0670fAa".parse()?;
    let data = "";
    
    // get the ID from the transaction receipt
    let tx = eth_bridge.deposit(recipient, data.into()).send().await?.get_receipt().await?;
    let id = tx.logs().get(0).unwrap().data().clone().data;
    let id_fixed: alloy::primitives::B256 = alloy::primitives::B256::from_slice(&id[..32]);

    let slot = get_signal_slot(&id_fixed, &eth_bridge.address());
    let proof   = get_proofs(&provider, slot, &signal_service).await?;
    let amount = 0;
    // This is the first deposit, so the nonce is zero. I think this is acceptable for testing purposes.
    // Other options: read the nonce from the DepositMade event, or add a nonce getter to the ETHBridge contract
    let nonce = 0;

    
    let template = fs::read_to_string("offchain/sample_deposit_proof.tmpl")?;
    let formatted = template
        .replace("{signal_service_address}", signal_service.address().to_string().as_str())
        .replace("{bridge_address}", eth_bridge.address().to_string().as_str())
        .replace("{block_hash}", proof.block_hash.to_string().as_str())
        .replace("{state_root}", proof.state_root.to_string().as_str())
        .replace("{account_proof_size}", proof.account_proof.len().to_string().as_str())
        .replace("{storage_proof_size}", proof.storage_proof.len().to_string().as_str())
        .replace("{populate_account_proof}", &expand_vector(proof.account_proof, "signalProof.accountProof"))
        .replace("{populate_storage_proof}", &expand_vector(proof.storage_proof, "signalProof.storageProof"))
        .replace("{nonce}", nonce.to_string().as_str())
        .replace("{sender}", signer.address().to_string().as_str())
        .replace("{recipient}", recipient.to_string().as_str())
        .replace("{amount}", amount.to_string().as_str())
        .replace("{data}", data)
        .replace("{slot}", proof.slot.to_string().as_str())
        .replace("{id}", id.to_string().as_str());
    println!("{}", formatted);
    Ok(())
}