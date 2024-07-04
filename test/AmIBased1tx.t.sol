// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AmIBased1tx} from "../src/AmIBased1tx.sol";

contract AmIBased1txTest is Test {
    AmIBased1tx public amIBased1tx;
    uint256 sepoliaFork;
    address payable owner = payable(address(0x767d76D5838b71F06456b70b4B2eB34EaD169A6d));

    function setUp() public {
        sepoliaFork = vm.createSelectFork("https://eth-sepolia.g.alchemy.com/v2/Ki8t6Gh4uTgsYlZg2oMehdE-Ns323whn");
        amIBased1tx = new AmIBased1tx();
        amIBased1tx.initialize(owner);
    }

    function test_Lock() public {
        vm.prank(owner);
        amIBased1tx.setLock(true);
    }

    function testFail_Lock() public {
        amIBased1tx.setLock(true);
    }
}
