use alloy::primitives::utils::parse_units;
use alloy::sol_types::SolCall;
use eyre::Result;

mod signal_slot;
use signal_slot::get_signal_slot;

use minimal_rollup::{
    deploy_eth_bridge, deploy_signal_service, get_proofs, get_provider, SignalProof,
};

use alloy::hex::{self, decode};
use alloy::primitives::{Address, Bytes, FixedBytes, U256};
use std::fs;

use alloy::sol;

sol! {
    function somePayableFunction(uint256 someArg) external payable returns (uint256);
    function someNonpayableFunction(uint256 someArg) external returns (uint256);
}

fn expand_vector(vec: Vec<Bytes>, name: &str) -> String {
    let mut expanded = String::new();
    for (i, item) in vec.iter().enumerate() {
        expanded += format!("\t\t{}[{}] = hex\"{}\";\n", name, i, item)
            .replace("0x", "")
            .as_str();
    }
    return expanded;
}

pub fn create_deposit_call(
    proof: SignalProof,
    nonce: usize,
    signer: Address,
    recipient: Address,
    amount: U256,
    data: &str,
    context: &str,
    id: &FixedBytes<32>,
) -> String {
    let mut result = String::new();
    result += format!("\n\t\t// Populate proof {}\n", nonce).as_str();
    result += format!(
        "\t\taccountProof = new bytes[]({});\n",
        proof.account_proof.len()
    )
    .as_str();
    result += expand_vector(proof.account_proof, "accountProof").as_str();
    result += format!(
        "\t\tstorageProof = new bytes[]({});\n",
        proof.storage_proof.len()
    )
    .as_str();
    result += expand_vector(proof.storage_proof, "storageProof").as_str();
    result += format!("\t\tdeposit.nonce = {};\n", nonce).as_str();
    result += format!("\t\tdeposit.from = address({});\n", signer).as_str();
    result += format!("\t\tdeposit.to = address({});\n", recipient).as_str();
    result += format!("\t\tdeposit.amount = {};\n", amount).as_str();
    result += format!("\t\tdeposit.data = bytes(hex\"{}\");\n", data).as_str();
    result += format!("\t\tdeposit.context = bytes(hex\"{}\");\n", context).as_str();
    result += format!("\t\t_createDeposit(\n\t\t\taccountProof,\n\t\t\tstorageProof,\n\t\t\tdeposit,\n\t\t\tbytes32({}),\n\t\t\tbytes32({})\n\t\t);\n", proof.slot, id).as_str();
    return result;
}

pub struct DepositSpecification {
    pub recipient: Address,
    pub amount: U256,
    pub data: String,
    pub context: String,
    pub canceler: Address,
}

fn deposit_specification() -> Vec<DepositSpecification> {
    // This is an address on the destination chain, so it seems natural to use one generated there
    // In this case, the CrossChainDepositExists.sol test case defines makeAddr("recipient");
    let recipient = "0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5";
    // Use both zero and non-zero amounts (in this case 4 ether)
    let amounts: Vec<U256> = vec![U256::ZERO, parse_units("4", "ether").unwrap().into()];

    // Use different calldata to try different functions and inputs
    let valid_payable_function_call = somePayableFunctionCall {
        someArg: U256::from(1234),
    }
    .abi_encode();
    let invalid_payable_function_call = somePayableFunctionCall {
        someArg: U256::from(1235),
    }
    .abi_encode();
    let valid_nonpayable_function_call = someNonpayableFunctionCall {
        someArg: U256::from(1234),
    }
    .abi_encode();

    let valid_payable_encoded = hex::encode(valid_payable_function_call);
    let invalid_payable_encoded = hex::encode(invalid_payable_function_call);
    let valid_nonpayable_encoded = hex::encode(valid_nonpayable_function_call);

    let calldata = vec![
        "",
        &valid_payable_encoded,
        &invalid_payable_encoded,
        &valid_nonpayable_encoded,
    ];

    let zero_canceler = Address::ZERO;

    let mut specifications = vec![];
    for amount in amounts {
        for data in calldata.iter() {
            specifications.push(DepositSpecification {
                recipient: recipient.parse().unwrap(),
                amount: U256::from(amount),
                data: data.to_string(),
                context: String::from(""),
                canceler: zero_canceler,
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
    let mut ids: Vec<FixedBytes<32>> = vec![];

    // Perform all deposits
    for (_i, spec) in deposits.iter().enumerate() {
        let tx = eth_bridge
            .deposit(
                spec.recipient,
                decode(spec.data.clone())?.into(),
                decode(spec.context.clone())?.into(),
                spec.canceler,
            )
            .value(spec.amount)
            .send()
            .await?
            .get_receipt()
            .await?;
        let id = tx.logs().get(0).unwrap().data().clone().data;
        ids.push(FixedBytes::from_slice(&id[..32]));
    }

    let mut block_hash = FixedBytes::ZERO;
    let mut state_root = FixedBytes::ZERO;

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
        populated_proofs += create_deposit_call(
            proof,
            i,
            signer.address(),
            d.recipient,
            d.amount,
            d.data.as_str(),
            d.context.as_str(),
            id,
        )
        .as_str();
    }

    let template = fs::read_to_string("offchain/tmpl/sample_deposit_proof.tmpl")?;
    let formatted = template
        .replace(
            "{signal_service_address}",
            signal_service.address().to_string().as_str(),
        )
        .replace(
            "{bridge_address}",
            eth_bridge.address().to_string().as_str(),
        )
        .replace("{block_hash}", block_hash.to_string().as_str())
        .replace("{state_root}", state_root.to_string().as_str())
        .replace("{populate_proofs}", populated_proofs.as_str());
    println!("{}", formatted);
    Ok(())
}
