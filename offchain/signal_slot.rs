use alloy::{
    node_bindings::Anvil,
    primitives::{address, b256, keccak256, Address, B256, U256},
    providers::{Provider, ProviderBuilder},
    signers::local::PrivateKeySigner,
    sol,
    sol_types::SolValue,
};
use eyre::Result;

const BLOCK_TIME: u64 = 1;
const ROLLUP_OPERATOR: Address = address!("0xCf03Dd0a894Ef79CB5b601A43C4b25E3Ae4c67eD");

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    SignalService,
    "./out/SignalService.sol/SignalService.json",
);

fn erc7201_slot(namespace: &Vec<u8>) -> B256 {
    let namespace_hash = keccak256(namespace);

    let namespace_hash_int = U256::from_be_bytes(namespace_hash.0) - U256::from(1);

    let slot = keccak256(&namespace_hash_int.to_be_bytes::<32>());

    let mut aligned_slot = slot;
    aligned_slot.0[31] = 0x00;

    aligned_slot
}

fn get_signal_slot(signal: &B256, sender: &Address) -> B256 {
    let namespace = (sender, signal).abi_encode_packed();
    return erc7201_slot(namespace.as_ref());
}

#[tokio::main]
async fn main() -> Result<()> {
    let signal: B256 =
        "0xe321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5".parse()?;

    let anvil = Anvil::new().block_time(BLOCK_TIME).try_spawn()?;
    let signer: PrivateKeySigner = anvil.keys()[0].clone().into();
    let deployer = signer.address();
    let slot = get_signal_slot(&signal, &deployer);
    println!("Slot: {:?}", slot);

    let rpc_url = anvil.endpoint_url();
    let provider = ProviderBuilder::new().wallet(signer).on_http(rpc_url);

    let contract = SignalService::deploy(&provider, ROLLUP_OPERATOR).await?;

    println!(
        "Deployed contract at address
    : {}",
        contract.address()
    );

    let builder = contract.sendSignal(signal);
    builder.send().await?.watch().await?;

    let state_root = provider
        .get_block_by_number(alloy::eips::BlockNumberOrTag::Latest)
        .await?
        .unwrap()
        .header
        .state_root;
    println!("State Root: {:?}", state_root);

    let e = b256!("0xdf4711e2bacf3407f4dd99aff960326754085972cf995e30e8ea995c9080ef00");
    let proof = provider
        .get_proof(contract.address().to_owned(), vec![e])
        .await?;
    println!("Storage Proof: {:?}", proof.storage_proof);
    println!("Account Proof: {:?}", proof.account_proof);
    Ok(())
}
