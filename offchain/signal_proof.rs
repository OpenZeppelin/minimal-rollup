use alloy::{
    node_bindings::Anvil,
    primitives::{address, bytes, Address, Bytes, FixedBytes, B256, U256},
    providers::{Provider, ProviderBuilder},
    rpc::types::EIP1186AccountProofResponse,
    signers::local::PrivateKeySigner,
    sol,
};
use eyre::{eyre, Result};
use serde_json::to_string_pretty;
use std::env;
use SignalService::SignalServiceInstance;

mod signal_slot;
use signal_slot::{get_signal_slot, NameSpaceConst};

const BLOCK_TIME: u64 = 1;
// NOTE: This needs to match the address of the rollup operator in the tests
// to ensure the signal service is deployed to the same address.
const ROLLUP_OPERATOR: Address = address!("0xCf03Dd0a894Ef79CB5b601A43C4b25E3Ae4c67eD");

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    SignalService,
    "./out/SignalService.sol/SignalService.json",
);

fn prompt_sender_and_signal() -> Result<(B256, Address, NameSpaceConst)> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 4 {
        return Err(eyre!(
            "Usage: cargo run --bin signal_proof <signal (0x...)> <sender (0x...)> <namespace (1 or 2)>"
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

    let namespace = NameSpaceConst::from_arg(&args[3])?;

    Ok((signal, sender, namespace))
}

async fn get_proofs(
    provider: &impl Provider,
    signal: &B256,
    sender: &Address,
    namespace: NameSpaceConst,
    signal_service: &SignalServiceInstance<(), &impl Provider>,
) -> Result<(FixedBytes<32>, EIP1186AccountProofResponse)> {
    let state_root = provider
        .get_block_by_number(alloy::eips::BlockNumberOrTag::Latest)
        .await?
        .unwrap()
        .header
        .state_root;

    let slot = get_signal_slot(&signal, &sender, namespace);
    let proof = provider
        .get_proof(signal_service.address().to_owned(), vec![slot])
        .await?;

    Ok((state_root, proof))
}

#[tokio::main]
async fn main() -> Result<()> {
    println!();
    let (signal, sender, namespace) = prompt_sender_and_signal()?;

    let anvil = Anvil::new()
        .block_time(BLOCK_TIME)
        .port(8547_u16)
        .try_spawn()?;
    let signer: PrivateKeySigner = anvil.keys()[0].clone().into();
    let rpc_url = anvil.endpoint_url();
    let provider = ProviderBuilder::new()
        .wallet(signer.clone())
        .on_http(rpc_url);

    let contract = SignalService::deploy(&provider, ROLLUP_OPERATOR).await?;

    println!("Deployed contract at address: {}", contract.address());

    if namespace == NameSpaceConst::ETHBridge {
        println!("Sending ETH deposit signal...");
        let builder = contract
            .deposit(sender, bytes!())
            .value(U256::from(4000000000000000000_u128));
        builder.send().await?.watch().await?;
    } else {
        println!("Sending normal signal...");
        let builder = contract.sendSignal(signal);
        builder.send().await?.watch().await?;
    }

    let (state_root, proof) = get_proofs(&provider, &signal, &sender, namespace, &contract).await?;

    println!("State Root: {}", state_root.to_string());
    println!("Storage Root: {}", proof.storage_hash.to_string());
    println!("Account Proof: {}", to_string_pretty(&proof.account_proof)?);
    println!("Storage Proof: {}", to_string_pretty(&proof.storage_proof)?);
    Ok(())
}
