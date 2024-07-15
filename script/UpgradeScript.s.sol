// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAmBased} from "../src/IAmBased.sol";
import {ProposeUpgradeResponse, Defender, Options} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UpgradeScript is Script {
    function setUp() public {}

    function test() public {}

    function run() public {
        Options memory opts;
        opts.referenceContract = "IAmBased.sol";
        ProposeUpgradeResponse memory response =
            Defender.proposeUpgrade(address(0xDCD03A4E74d2098087462A5B7e4caaA73b722d53), "IAmBased.sol", opts);
        console.log("Proposal id", response.proposalId);
        console.log("Url", response.url);
    }
}
