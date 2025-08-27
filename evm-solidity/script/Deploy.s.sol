// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {Token} from "src/Token.sol";
import {AccessManager} from "src/AccessManager.sol";
import {Oracle} from "src/Oracle.sol";
import "src/Vault.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        vm.startBroadcast(pk);

        AccessManager manager = new AccessManager(deployer, deployer);
        Token token = new Token("Sample Token", "SAMP", deployer);
        Oracle oracle = new Oracle(deployer, 1e8);
        Vault vault = new Vault(IERC20Like(address(token)), deployer, IOracleLike(address(oracle)));

        token.setManager(address(manager));
        token.setMinter(address(manager));
        manager.setShouldMintOnTransfer(true);

        vm.stopBroadcast();

        console2.log("AccessManager:", address(manager));
        console2.log("Token:", address(token));
        console2.log("Oracle:", address(oracle));
        console2.log("Vault:", address(vault));
    }
}
