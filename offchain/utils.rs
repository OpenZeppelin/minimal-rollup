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
    let contract = ETHBridge::deploy(provider, signal_service, trusted_publisher).await?;
    Ok(contract)
}

pub async fn get_proofs(
    provider: &impl Provider,
    slot: B256,
    signal_service: &SignalServiceInstance<(), &impl Provider>,
) -> Result<()> {
    let state_root = provider
        .get_block_by_number(alloy::eips::BlockNumberOrTag::Latest)
        .await?
        .unwrap()
        .header
        .state_root;

    let proof = provider
        .get_proof(signal_service.address().to_owned(), vec![slot])
        .await?;

    println!("State Root: {}", state_root.to_string());
    println!("Storage Root: {}", proof.storage_hash.to_string());
    println!("Account Proof: {}", to_string_pretty(&proof.account_proof)?);
    println!("Storage Proof: {}", to_string_pretty(&proof.storage_proof)?);

    Ok(())
}

#[allow(dead_code)]
fn main() {}
