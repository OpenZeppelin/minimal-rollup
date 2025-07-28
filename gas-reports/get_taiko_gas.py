import requests
import math
import json
from typing import List, Dict, Any

# Taiko Inbox contract address
CONTRACT_ADDRESS = "0x06a9ab27c7e2255df1815e6cc0168d7755feb19a"

def fetch_transactions(contract_address: str, limit: int = 20) -> Dict[str, Any]:
    url = f"https://api.tenderly.co/api/v1/public-contract/1/address/{contract_address}/explorer/transactions"
    params = {"limit": limit}
    
    try:
        response = requests.get(url, params=params)
        response.raise_for_status() 
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data from Tenderly API: {e}")
        return {}

def extract_propose_batch_gas(transactions: List[Dict[str, Any]]) -> Dict[str, Any]:
    sum_gas_used = 0
    num_propose_batch = 0
    min_gas_used = 0
    max_gas_used = 0
    for tx in transactions:
        # make sure it calls propose batch AND its a blob txs
        if tx.get("method") == "proposeBatch" and len(tx.get("blob_versioned_hashes")) != 0:
                sum_gas_used += tx.get("gas_used")
                num_propose_batch += 1
                print(f"Transaction {tx.get("hash")} used {tx.get('gas_used')} gas")
                if tx.get("gas_used") < min_gas_used or min_gas_used == 0:
                    min_gas_used = tx.get("gas_used")
                if tx.get("gas_used") > max_gas_used or max_gas_used == 0:
                    max_gas_used = tx.get("gas_used")

    average_gas_used = math.ceil(sum_gas_used / num_propose_batch)

    return {
        "total_transactions": num_propose_batch,
        "average_gas_used_proposeBatch": average_gas_used,
        "minimum_gas_used": min_gas_used ,
        "maximum_gas_used": max_gas_used 
    }
    

def main():
    print(f"Fetching transactions for contract: {CONTRACT_ADDRESS}")
    print("-" * 60)
    
    response = fetch_transactions(CONTRACT_ADDRESS)
    
    if response is None:
        print("Failed to fetch transactions")
        return
    
    transactions = response if isinstance(response, list) else response.get("data", [])
    
    print(f"Total transactions fetched: {len(transactions)}")
    
    propose_batch_txs_summary = extract_propose_batch_gas(transactions)
    
    print(f"Found {propose_batch_txs_summary['total_transactions']} proposeBatch transactions")
    print("-" * 60)
    
    print(f"Average gas_used over {propose_batch_txs_summary["total_transactions"]} propose transactions: {propose_batch_txs_summary['average_gas_used_proposeBatch']:,}") 
    
    with open("./gas-reports/propose_batch_gas_analysis.json", "w") as f:
        json.dump(propose_batch_txs_summary, f, indent=2)
    
    print("\nResults saved to 'propose_batch_gas_analysis.json'")

if __name__ == "__main__":
    main()
