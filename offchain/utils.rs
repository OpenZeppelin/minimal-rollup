use alloy::{
    node_bindings::{Anvil, AnvilInstance},
    primitives::{address, Address, B256},
    providers::{Provider, ProviderBuilder},
    signers::local::PrivateKeySigner,
    sol,
};

use ETHBridge::ETHBridgeInstance;
use SignalService::SignalServiceInstance;

use eyre::Result;
use serde_json::to_string_pretty;

const BLOCK_TIME: u64 = 5;

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    SignalService,
    "./out/SignalService.sol/SignalService.json",
);

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    ETHBridge,
    "./out/ETHBridge.sol/ETHBridge.json"
);

pub fn get_provider() -> Result<(impl Provider, AnvilInstance)> {
    let anvil = Anvil::new()
        .block_time(BLOCK_TIME)
        .port(8547_u16)
        .try_spawn()?;
    let signer: PrivateKeySigner = anvil.keys()[0].clone().into();
    let rpc_url = anvil.endpoint_url();
    let provider = ProviderBuilder::new()
        .wallet(signer.clone())
        .on_http(rpc_url);
    Ok((provider, anvil))
}

pub async fn deploy_signal_service(
    provider: &impl Provider,
) -> Result<SignalServiceInstance<(), &impl Provider>> {
    let contract = SignalService::deploy(provider).await?;
    Ok(contract)
}

pub async fn deploy_eth_bridge(
    provider: &impl Provider,
    signal_service: Address,
    trusted_publisher: Address,
) -> Result<ETHBridgeInstance<(), &impl Provider>> {
    // L2 Eth bridge address
    let counterpart = address!("0xDC9e4C83bDe3912E9B63A9BF9cE263F3309aB5d4");
    // WARN: This is a slight hack for now to make sure the contract is deployed on the correct address
    ETHBridge::deploy(provider, signal_service, trusted_publisher, counterpart).await?;

    let contract =
        ETHBridge::deploy(provider, signal_service, trusted_publisher, counterpart).await?;

    Ok(contract)
}

pub async fn get_proofs(
    provider: &impl Provider,
    slot: B256,
    signal_service: &SignalServiceInstance<(), &impl Provider>,
) -> Result<()> {
    let block_header = provider
        .get_block_by_number(alloy::eips::BlockNumberOrTag::Latest)
        .await?
        .unwrap()
        .header;

    let proof = provider
        .get_proof(signal_service.address().to_owned(), vec![slot])
        .await?;

    println!("Block Hash: {}", block_header.hash.to_string());
    println!("State Root: {}", block_header.state_root.to_string());
    println!("Storage Root: {}", proof.storage_hash.to_string());
    println!("Account Proof: {}", to_string_pretty(&proof.account_proof)?);
    println!("Storage Proof: {}", to_string_pretty(&proof.storage_proof)?);

    Ok(())
}

#[allow(dead_code)]
fn main() {}
