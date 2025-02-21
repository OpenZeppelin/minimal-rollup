// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../../DataFeed.sol";
import "../../Inbox.sol";
import "../TaikoMetadataProvider.sol";

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployProtocolOnL1 is Script {
    uint256 public maxAnchorBlockIdOffset = vm.envUint("MAX_ANCHOR_BLOCK_ID_OFFSET");
    bytes32 public genesis = vm.envBytes32("GENESIS");

    modifier broadcast() {
        require(vm.envUint("PRIVATE_KEY") != 0, "invalid priv key");
        require(maxAnchorBlockIdOffset != 0, "empty max anchor id offset");
        require(genesis != 0, "empty genesis");
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external broadcast {
        address dataFeed = deployProxy({name: "data_feed", impl: address(new DataFeed()), data: ""});

        // TODO: LookHead contract is not yet implemented， use address(0) instead
        deployProxy({
            name: "taiko_metadata_provider",
            impl: address(new TaikoMetadataProvider(maxAnchorBlockIdOffset, address(0))),
            data: ""
        });

        // TODO: Verifier contract is not yet implemented， use address(0) instead
        deployProxy({name: "inbox", impl: address(new Inbox(genesis, dataFeed, address(0))), data: ""});
    }

    function deployProxy(string memory name, address impl, bytes memory data) internal returns (address proxy) {
        proxy = address(new ERC1967Proxy(impl, data));

        console2.log("  name      :", proxy);
        console2.log("  proxy      :", proxy);
        console2.log("  impl       :", impl);

        vm.writeJson(
            vm.serializeAddress("deployment", name, proxy),
            string.concat(vm.projectRoot(), "/taiko/deployments/deploy_l1.json")
        );
    }
}
