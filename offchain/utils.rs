use alloy::{
    node_bindings::{Anvil, AnvilInstance},
    primitives::{address, Address, Bytes, B256},
    providers::{Provider, ProviderBuilder},
    signers::local::PrivateKeySigner,
    sol,
};

use ETHBridge::ETHBridgeInstance;
use SignalService::SignalServiceInstance;

use eyre::Result;

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

#[allow(dead_code)]
pub struct SignalProof {
    pub block_hash: B256,
    pub state_root: B256,
    pub slot: B256,
    pub account_proof: Vec<Bytes>,
    pub storage_proof: Vec<Bytes>,
}

pub fn get_provider() -> Result<(impl Provider, AnvilInstance, PrivateKeySigner)> {
    let anvil = Anvil::new()
        .block_time(BLOCK_TIME)
        .port(8547_u16)
        .try_spawn()?;
    let signer: PrivateKeySigner = anvil.keys()[0].clone().into();
    let rpc_url = anvil.endpoint_url();
    let provider = ProviderBuilder::new()
        .wallet(signer.clone())
        .on_http(rpc_url);
    Ok((provider, anvil, signer))
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
) -> Result<ETHBridgeInstance<(), &impl Provider>> {
    // The trusted publisher and counterpart are needed to verify signals from the other bridge
    // In this case, we are only depositing on this bridge
    // Set both values to an arbitrary dummy address. It is non-zero to pass validation.
    let unused = address!("0x0000000000000000000000000000000000000001");
    let contract = ETHBridge::deploy(provider, signal_service, unused, unused).await?;
    Ok(contract)
}

pub async fn get_proofs(
    provider: &impl Provider,
    slot: B256,
    signal_service: &SignalServiceInstance<(), &impl Provider>,
) -> Result<SignalProof> {
    let block_header = provider
        .get_block_by_number(alloy::eips::BlockNumberOrTag::Latest)
        .await?
        .unwrap()
        .header;

    let proof = provider
        .get_proof(signal_service.address().to_owned(), vec![slot])
        .await?;

    let proof = SignalProof {
        block_hash: block_header.hash,
        state_root: block_header.state_root,
        slot: slot,
        account_proof: proof.account_proof,
        storage_proof: proof.storage_proof[0].clone().proof,
    };

    Ok(proof)
}

#[allow(dead_code)]
fn main() {}
