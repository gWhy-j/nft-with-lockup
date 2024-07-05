// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {AmIBased1tx} from "../src/AmIBased1tx.sol";

contract AmIBased1txTest is Test {
    AmIBased1tx public amIBased1tx;
    uint256 sepoliaFork;
    address user1;
    address user2;
    address payable deployer = payable(address(0xeA4a5BA5b31D585116D6921A859F0c39707771B3));
    bytes sig1 =
        hex"a69c511c5705672f1b6513359c2b4c1174ee06f8db19d198833a552e21de35b51a129c233d49ac0bba606934d0273c823b4485380ac2b1594b991db2166490a81c";
    bytes sig2 =
        hex"8bed86b4b2ada8e62425203bfcb6d26e9e9964786a28ad802190233df920fc1d7c25871d823779268ad12d28089c3ba29389826fe73f3b4a911963938cb3a6af1c";
    bytes inValidSig =
        hex"f31c59fb9029fb46b4c2cbbcb2fae912da7bc7ab08974540d08d5ed786ad06ec6dd3278e8efc165c99a9eb52e54223db70e02e3818248d6b5d1288a07e6ef36a1b";
    // messageHash1: 0x4494b5dc4de96e39d6928528721f3d97da26c8a0e7492fd81ab0dbae96aeb2ea
    bytes32 messageHash1 = keccak256(
        abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(uint256(100), "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7"))
        )
    );
    // messageHash2: 0xc254efecd2f2f72b293efdc19c45c73a53de3f9372a9320e6202f2dd34ce2a5a
    bytes32 messageHash2 = keccak256(
        abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(uint256(200), "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8"))
        )
    );

    function setUp() public {
        sepoliaFork = vm.createSelectFork("https://eth-sepolia.g.alchemy.com/v2/Ki8t6Gh4uTgsYlZg2oMehdE-Ns323whn");
        Vm.Wallet memory wallet1 = vm.createWallet(uint256(keccak256(bytes("1"))));
        user1 = wallet1.addr;
        Vm.Wallet memory wallet2 = vm.createWallet(uint256(keccak256(bytes("2"))));
        user2 = wallet2.addr;
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.startPrank(deployer);
        amIBased1tx = new AmIBased1tx();
        amIBased1tx.initialize(deployer, 200000000000000);
        vm.stopPrank();
    }

    function test_UnLock() public {
        vm.prank(deployer);
        amIBased1tx.setLock(false);
    }

    function testFail_UnLock() public {
        amIBased1tx.setLock(false);
    }

    function test_JustMint() public {
        vm.startPrank(user1);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        vm.stopPrank();
    }

    function test_Mint() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        string memory tokenURI = amIBased1tx.tokenURI(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        assertEq(tokenURI, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7");
        assertEq(amIBased1tx.balanceOf(user1), 1);
        vm.stopPrank();
    }

    function test_MintAndTransfer() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        vm.stopPrank();
        assertEq(amIBased1tx.balanceOf(user1), 1);
        assertEq(amIBased1tx.balanceOf(deployer), 0);

        vm.prank(deployer);
        amIBased1tx.setLock(false);

        vm.prank(user1);
        amIBased1tx.transferFrom(user1, deployer, newTokenId);
        assertEq(amIBased1tx.balanceOf(user1), 0);
        assertEq(amIBased1tx.balanceOf(deployer), 1);

        assertEq(amIBased1tx.ownerOf(newTokenId), deployer);
    }

    function testFail_MintAndTransfer() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);

        amIBased1tx.transferFrom(user1, deployer, newTokenId);
        vm.stopPrank();
    }

    function test_MintAndSafeTransferFrom() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        vm.stopPrank();

        vm.prank(deployer);
        amIBased1tx.setLock(false);

        vm.prank(user1);
        amIBased1tx.safeTransferFrom(user1, deployer, newTokenId);

        assertEq(amIBased1tx.ownerOf(newTokenId), deployer);
    }

    function testFail_MintAndSafeTransferFrom() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);

        amIBased1tx.safeTransferFrom(user1, deployer, newTokenId);
        vm.stopPrank();
    }

    function testFail_MintTwice() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(deployer);
        amIBased1tx.setLock(false);

        vm.prank(user1);
        amIBased1tx.transferFrom(user1, deployer, firstNFT);

        vm.prank(user1);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );
    }

    function test_SetTokenURIFromValidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user2);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", sig2);
    }

    function test_SetTokenURIAfterTradeNFT() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user2);
        uint256 secondNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(deployer);
        amIBased1tx.setLock(false);

        vm.prank(user2);
        amIBased1tx.transferFrom(user2, user1, secondNFT);

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", sig2);
        vm.prank(user1);
        amIBased1tx.updateTokenInfo(secondNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", sig2);

        assertEq(amIBased1tx.ownerOf(secondNFT), user1);
        assertEq(amIBased1tx.getScore(firstNFT), 200);
        assertEq(amIBased1tx.getScore(secondNFT), 200);
    }

    function testFail_SetTokenURIWithInvalidSig() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", inValidSig);
    }

    function testFail_SetTokenURIFromInvalidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user2);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", sig1, deployer
        );

        vm.prank(user2);
        amIBased1tx.updateTokenInfo(firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", sig2);
    }
}
