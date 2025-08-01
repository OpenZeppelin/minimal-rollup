import json

def load_json_file(filename):
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found")
        return None
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file '{filename}'")
        return None

def compare_gas_usage(propose_batch_data, publish_data):
    propose_batch_avg = propose_batch_data.get('average_gas_used_proposeBatch', 0)
    publish_gas = publish_data.get('average_gas_used_publish', 0)
    
    if propose_batch_avg == 0:
        return {"error": "proposeBatch average gas is zero"}

    if publish_gas == 0:
        return {"error": "Publish average gas is zero"}
    
    difference = propose_batch_avg - publish_gas
    
    return {
        "propose_batch_avg_gas": propose_batch_avg,
        "publish_avg_gas": publish_gas,
        "difference": difference,
    }


def calculate_difference(value1, value2):
    diff = value1 - value2
    percentage_decrease = (diff / value1) * 100 if value1 != 0 else 0
    return percentage_decrease


def main():
    propose_batch_data = load_json_file('./gas-reports/propose_batch_gas_analysis.json')
    publish_data = load_json_file('./gas-reports/minimal_inbox_publish.json')
    
    results = compare_gas_usage(propose_batch_data, publish_data)
    print(results)
    
    propose_batch_avg_gas = results['propose_batch_avg_gas']
    publish_avg_gas = results['publish_avg_gas']
    difference = results['difference']
    
    print("Gas Usage Comparison Analysis")
    print("=" * 50)
    print(f"proposeBatch average gas used: {propose_batch_avg_gas:,}")
    print(f"Publish average gas used: {publish_avg_gas:,}")
    print(f"Difference: {difference:,}")
    
    percent_decrease = calculate_difference(propose_batch_avg_gas, publish_avg_gas)
    
    if percent_decrease > 0:
        print(f"minimal_rollup_inbox_publish uses {percent_decrease:.2f}% LESS gas than alethia_inbox_propose")
    elif percent_decrease < 0:
        print(f"minimal_rollup_inbox_publish uses {abs(percent_decrease):.2f}% MORE gas than alethia_inbox_propose")
    else:
        print("Both methods use the same amount of gas")
    
    results['percent_decrease'] = round(percent_decrease, 2)
    
    with open("./gas-reports/gas_comparison_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print("=" * 50)
    
    print("\nResults saved to './gas-reports/gas_comparison_results.json'")

if __name__ == "__main__": 
    main()
