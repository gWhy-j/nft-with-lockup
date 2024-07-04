// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AmIBased1tx} from "../src/AmIBased1tx.sol";
import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    AmIBased1tx amIBased1tx;
    address owner = address(0x767d76D5838b71F06456b70b4B2eB34EaD169A6d);
    address admin = address(0x5EE02121812199335f9A820838620b6Db37595d3);

    function setUp() public {}

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
            "AmIBased1tx.sol", admin, abi.encodeCall(AmIBased1tx.initialize, (owner)), opts
        );

        console.log("Proxy address: %s", proxy);

        // vm.stopBroadcast();
    }
}
