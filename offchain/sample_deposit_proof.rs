
use eyre::Result;

mod signal_slot;
use signal_slot::get_signal_slot;

mod utils;
use utils::{deploy_eth_bridge, deploy_signal_service, get_proofs, get_provider, SignalProof};

use alloy::primitives::{Address, Bytes, U256, FixedBytes};
use alloy::hex::decode;
use std::fs;




fn expand_vector(vec: Vec<Bytes>, name: &str) -> String {
    let mut expanded = String::new();
    for (i, item) in vec.iter().enumerate() {
        expanded += format!("\t\t{}[{}] = hex\"{}\";\n", name, i, item).replace("0x","").as_str();
    }
    return expanded;
}

fn create_deposit_call(proof: SignalProof, nonce: usize, signer: Address, recipient: Address, amount: U256, data: &str, id: &FixedBytes<32>) -> String {
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
    result += format!("\t\tdeposit.data = bytes(hex\"{}\");\n", data).as_str();
    result += format!("\t\t_createDeposit(\n\t\t\taccountProof,\n\t\t\tstorageProof,\n\t\t\tdeposit,\n\t\t\tbytes32({}),\n\t\t\tbytes32({})\n\t\t);\n", proof.slot, id).as_str();
    return result;
}

pub struct DepositSpecification {
    pub recipient: Address,
    pub amount: U256,
    pub data: String,
}

fn deposit_specification() -> Vec<DepositSpecification> {

    // This is an address on the destination chain, so it seems natural to use one generated there
    // In this case, the CrossChainDepositExists.sol test case defines _randomAddress("recipient");        
    let recipient = "0x99A270Be1AA5E97633177041859aEEB9a0670fAa";
    // Use both zero and non-zero amounts (in this case 4 ether)
    let amounts = vec![0_u128, 4000000000000000000_u128];
    // Use different calldata to try different functions and inputs
    let calldata = vec![
        "", // empty
        "9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2", // (valid) call to somePayableFunction(1234)
        "9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3", // (invalid) call to somePayableFunction(1235)
        "5932a71200000000000000000000000000000000000000000000000000000000000004d2" // (valid) call to `someNonPayableFunction(1234)`
    ];

    let mut specifications = vec![];
    for amount in amounts {
        for data in calldata.iter() {
            specifications.push(DepositSpecification {
                recipient: recipient.parse().unwrap(),
                amount: U256::from(amount),
                data: data.to_string()
            });
        }
    }
    return specifications;
}

#[tokio::main]
async fn main() -> Result<()> {
    let (provider, _anvil, signer) = get_provider()?;
    let signal_service = deploy_signal_service(&provider).await?;
    let eth_bridge = deploy_eth_bridge(&provider, *signal_service.address()).await?;
    
    let deposits = deposit_specification();
    assert!(deposits.len() > 0, "No deposits to prove");
    let mut ids: Vec<FixedBytes<32>>  = vec![];
    // Perform all deposits
    for (_i, spec) in deposits.iter().enumerate() {
        let tx = eth_bridge.deposit(spec.recipient, decode(spec.data.clone())?.into()).value(spec.amount).send().await?.get_receipt().await?;
        let id = tx.logs().get(0).unwrap().data().clone().data;
        ids.push(FixedBytes::from_slice(&id[..32]));
    }

    let mut block_hash = FixedBytes::ZERO;
    let mut state_root= FixedBytes::ZERO;

    let mut populated_proofs = String::new();
    for (i, id) in ids.iter().enumerate() {
        let slot = get_signal_slot(id, &eth_bridge.address());
        let proof = get_proofs(&provider, slot, &signal_service).await?;
    
        if i == 0 {
            block_hash = proof.block_hash;
            state_root = proof.state_root;
        } else {
            assert!(proof.block_hash == block_hash);
            assert!(proof.state_root == state_root);
        }

        let d = &deposits[i];
        populated_proofs += create_deposit_call(proof, i, signer.address(), d.recipient, d.amount, d.data.as_str(), id).as_str();
    }

    let template = fs::read_to_string("offchain/sample_deposit_proof.tmpl")?;
    let formatted = template
        .replace("{signal_service_address}", signal_service.address().to_string().as_str())
        .replace("{bridge_address}", eth_bridge.address().to_string().as_str())
        .replace("{block_hash}", block_hash.to_string().as_str())
        .replace("{state_root}", state_root.to_string().as_str())
        .replace("{populate_proofs}", populated_proofs.as_str());
    println!("{}", formatted);
    Ok(())
}