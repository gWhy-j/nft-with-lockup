// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAmBased} from "../src/IAmBased.sol";
import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    IAmBased iAmBased;
    address eventOwner = address(0xba6419c1f65F447eF6f19942bBee3BF281C6c521);
    address unveiledLedger = address(0x77bbFD2d630A9123Ae5da78a7Af8856983223c8A);
    // address admin = address(0xf6ad1c61B3EA75F1c3059b77B92300883c1EccD8);
    address admin = address(0x5EE02121812199335f9A820838620b6Db37595d3); // Sepolia

    function setUp() public {}

    function test() public {}

    function run() public {
        // uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        // vm.startBroadcast(deployerPrivateKey);

        ApprovalProcessResponse memory upgradeApprovalProcess = Defender.getUpgradeApprovalProcess();

        if (upgradeApprovalProcess.via == address(0)) {
            revert(
                string.concat(
                    "Upgrade approval process with id ",
                    upgradeApprovalProcess.approvalProcessId,
                    " has no assigned address"
                )
            );
        }

        Options memory opts;
        opts.defender.useDefenderDeploy = true;

        address proxy = Upgrades.deployTransparentProxy(
            "IAmBased.sol",
            admin,
            abi.encodeCall(IAmBased.initialize, (unveiledLedger, 200000000000000, eventOwner)),
            opts
        );

        console.log("Proxy address: %s", proxy);

        // vm.stopBroadcast();
    }
}
