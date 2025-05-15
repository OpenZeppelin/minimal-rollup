
use eyre::Result;

mod signal_slot;
use signal_slot::get_signal_slot;

mod utils;
use utils::{deploy_eth_bridge, deploy_signal_service, get_proofs, get_provider, SignalProof};

use alloy::primitives::{Address, Bytes, U256};
use std::fs;


fn expand_vector(vec: Vec<Bytes>, name: &str) -> String {
    let mut expanded = String::new();
    for (i, item) in vec.iter().enumerate() {
        expanded += format!("\t\t{}[{}] = hex\"{}\";\n", name, i, item).replace("0x","").as_str();
    }
    return expanded;
}

fn create_deposit_call(proof: SignalProof, nonce: i32, signer: Address, recipient: Address, amount: U256, data: &str, id: Bytes) -> String {
    let mut result = String::new();
    result += format!("\n\t\t// Populate proof {}\n", nonce).as_str();
    result += format!("\t\taccountProof = new bytes[]({});\n", proof.account_proof.len()).as_str();
    result += expand_vector(proof.account_proof, "accountProof").as_str();
    result += format!("\t\tstorageProof = new bytes[]({});\n", proof.storage_proof.len()).as_str();
    result += expand_vector(proof.storage_proof, "storageProof").as_str();
    result += format!("\t\tdeposit.nonce = {};\n", nonce).as_str();
    result += format!("\t\tdeposit.from = address({});\n", signer).as_str();
    result += format!("\t\tdeposit.to = address({});\n", recipient).as_str();
    result += format!("\t\tdeposit.amount = {};\n", amount).as_str();
    result += format!("\t\tdeposit.data = bytes(\"{}\");\n", data).as_str();
    result += format!("\t\t_createDeposit(\n\t\t\taccountProof,\n\t\t\tstorageProof,\n\t\t\tdeposit,\n\t\t\tbytes32({}),\n\t\t\tbytes32({})\n\t\t);\n", proof.slot, id).as_str();
    return result;
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
    let amount = U256::from(4000000000000000000_u128); // 4 ether
    
    // get the ID from the transaction receipt
    let tx = eth_bridge.deposit(recipient, data.into()).value(amount).send().await?.get_receipt().await?;
    let id = tx.logs().get(0).unwrap().data().clone().data;
    let id_fixed: alloy::primitives::B256 = alloy::primitives::B256::from_slice(&id[..32]);

    let slot = get_signal_slot(&id_fixed, &eth_bridge.address());
    let proof   = get_proofs(&provider, slot, &signal_service).await?;

    // This is the first deposit, so the nonce is zero. I think this is acceptable for testing purposes.
    // Other options: read the nonce from the DepositMade event, or add a nonce getter to the ETHBridge contract
    let nonce = 0;

    
    let template = fs::read_to_string("offchain/sample_deposit_proof.tmpl")?;
    let formatted = template
        .replace("{signal_service_address}", signal_service.address().to_string().as_str())
        .replace("{bridge_address}", eth_bridge.address().to_string().as_str())
        .replace("{block_hash}", proof.block_hash.to_string().as_str())
        .replace("{state_root}", proof.state_root.to_string().as_str())
        .replace("{populate_proofs}", create_deposit_call(proof, nonce, signer.address(), recipient, amount, data, id).as_str());
    println!("{}", formatted);
    Ok(())
}