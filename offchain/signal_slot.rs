use std::env;

use alloy::{
    primitives::{keccak256, Address, B256, U256},
    sol_types::SolValue,
};
use eyre::{eyre, Result};

pub fn erc7201_slot(namespace: &Vec<u8>) -> B256 {
    let namespace_hash = keccak256(namespace);

    let namespace_hash_int = U256::from_be_bytes(namespace_hash.0) - U256::from(1);

    let slot = keccak256(&namespace_hash_int.to_be_bytes::<32>());

    let mut aligned_slot = slot;
    aligned_slot.0[31] = 0x00;

    aligned_slot
}

pub fn get_signal_slot(signal: &B256, sender: &Address) -> B256 {
    let namespace = (signal, sender).abi_encode_packed();
    return erc7201_slot(namespace.as_ref());
}

#[allow(dead_code)]
fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        return Err(eyre!(
            "Usage: cargo run --bin signal_slot <signal (0x...)> <sender (0x...)>"
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

    println!("Signal Slot: {:?}", get_signal_slot(&signal, &sender));
    Ok(())
}
