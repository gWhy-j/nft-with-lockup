// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {AmIBased1tx} from "../src/AmIBased1tx.sol";

// forge test --match-contract AmIBased1txTest -vvv --gas-report

contract AmIBased1txTest is Test {
    AmIBased1tx public amIBased1tx;
    uint256 sepoliaFork;
    address user1 = address(0x1d8e5a1c88aCfccED410f1a7A89237BA11FaF02F);
    address user2 = address(0x2300Ed1feECD5Fe7D1913DD3eB4699aC05D16122);
    address payable deployer = payable(address(0xeA4a5BA5b31D585116D6921A859F0c39707771B3));
    uint256 validTimestamp = 1770186688;
    uint256 invalidTimestamp = 1710187779;

    bytes user1FirstSig =
        hex"5f11bbfad858e796a4c6d342ce51249ff0a57d7148162a3fd1fc245c9c1e92113ddb36fee0a0dd03144dd948e44d117383f0c1b1a65fb4f0daef4e59ad2cf2261c";
    bytes user1SecondSig =
        hex"39fbcf3feef4c058b2add5c446115a0c8ae2a334467e65c973f794ddc196ed3d55e936d4fe1a41cc9a4bb2777f5c027a11a51a65065ce880aaa750da334e93e31b";
    bytes user1InvalidSig =
        hex"a25433d3b90e7bd031f133ec3bb2fdd431469bee754632c4c7a34e4e11efd85335d64a625e153347494354beb21c9cf570bca2a537951c036a18f6a14f5afae61c";
    bytes user2FirstSig =
        hex"b2e93a9e262ff6824a063653b8ee0431b60d9d4315e292be3ea48d63a1536253083abe3bfb4123abdd8bbec0962c044ba2452e38cdcd4056024c25c7768ba2361c";
    bytes user2SecondSig =
        hex"0d25d8b4690e8e649cbb281c681484264d7d16925d2f99670ae5b577f41440fc40918fcdd81ea8eb03e4f7ddec6747e5e10a94ecc6e92f60eadaa444e442e4521b";
    bytes user2InvalidSig =
        hex"97d9268c1804d3244e98fbc4f049d7695e953da89189caedc060c02109291ab278a563623804a8232e8cd75d569e47e00213d1e4ee50e5cb0e8967cac89b1d291b";

    function setUp() public {
        sepoliaFork = vm.createSelectFork("https://eth-sepolia.g.alchemy.com/v2/Ki8t6Gh4uTgsYlZg2oMehdE-Ns323whn");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.startPrank(deployer);
        amIBased1tx = new AmIBased1tx();
        amIBased1tx.initialize(deployer, 200000000000000);
        vm.stopPrank();
    }

    function test_SupportsInterface() public view {
        require(amIBased1tx.supportsInterface(0x80ac58cd));
        require(amIBased1tx.supportsInterface(0x49064906));
    }

    function test_UnLock() public {
        vm.prank(deployer);
        amIBased1tx.setLock(false);
        assertEq(amIBased1tx.getLockStatus(), false);
    }

    function test_Lock() public {
        vm.prank(deployer);
        amIBased1tx.setLock(true);
        assertEq(amIBased1tx.getLockStatus(), true);
    }

    function testFail_UnLock() public {
        amIBased1tx.setLock(false);
    }

    function test_DataValidCheck() public {
        vm.prank(user1);
        amIBased1tx.amIBased{value: 200000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        require(
            amIBased1tx.dataValidCheck(
                deployer,
                user1,
                0,
                100,
                "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7",
                validTimestamp,
                user1FirstSig
            )
        );
    }

    function testFail_DataValidCheck() public {
        vm.prank(user1);
        amIBased1tx.amIBased{value: 200000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        require(
            amIBased1tx.dataValidCheck(
                deployer,
                user1,
                0,
                200,
                "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7",
                validTimestamp,
                user1FirstSig
            )
        );
    }

    function test_JustMint() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 200000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        string memory tokenURI = amIBased1tx.tokenURI(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        assertEq(tokenURI, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7");
        assertEq(amIBased1tx.balanceOf(user1), 1);
        assertEq(amIBased1tx.totalSupply(), 1);
        vm.stopPrank();
    }

    function test_Mint() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(deployer).balance;
        uint256 score = amIBased1tx.getScore(newTokenId);
        string memory tokenURI = amIBased1tx.tokenURI(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        assertEq(tokenURI, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7");
        assertEq(amIBased1tx.balanceOf(user1), 1);
        assertEq(amIBased1tx.totalSupply(), 1);
        vm.stopPrank();
    }

    function testFail_Mint() public {
        vm.startPrank(user1);
        amIBased1tx.amIBased{value: 100000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        vm.stopPrank();
    }

    function test_MintAndTransfer() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(deployer).balance;
        uint256 newTokenId = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
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
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
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
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
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
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
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
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(deployer);
        amIBased1tx.setLock(false);

        vm.prank(user1);
        amIBased1tx.transferFrom(user1, deployer, firstNFT);

        vm.prank(user1);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
    }

    function test_SetTokenURIFromValidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(
            firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", validTimestamp, user1SecondSig
        );
    }

    function testFail_SetTokenURIFromInvalidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user2);
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user2FirstSig, deployer
        );

        vm.prank(user2);
        amIBased1tx.updateTokenInfo(
            firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", validTimestamp, user2SecondSig
        );
    }

    function testFail_SetTokenURIWithInvalidScore() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(
            firstNFT, 250, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", validTimestamp, user1SecondSig
        );
    }

    function testFail_SetTokenURIWithInvalidTimestamp() public {
        vm.prank(user1);
        uint256 firstNFT = amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        amIBased1tx.updateTokenInfo(
            firstNFT, 200, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw8", invalidTimestamp, user1InvalidSig
        );
    }

    function testFail_ChangeFee() public {
        vm.prank(user1);
        amIBased1tx.setFee(300000000000000);
    }

    function test_ChangeFee() public {
        vm.startPrank(user1);
        uint256 TreasuryBalance1 = address(deployer).balance;
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user1FirstSig, deployer
        );
        uint256 TreasuryBalance2 = address(deployer).balance;
        vm.stopPrank();
        assertEqUint(TreasuryBalance2 - TreasuryBalance1, 200000000000000);

        vm.prank(deployer);
        amIBased1tx.setFee(300000000000000);
        assertEq(amIBased1tx.getFee(), 300000000000000);

        vm.startPrank(user2);
        uint256 TreasuryBalance3 = address(deployer).balance;
        amIBased1tx.amIBased{value: 500000000000000}(
            100, "ipfs://QmPMaxM9eQcz9wzLd8XXAHtCTyW5zqQzeVD3X88XcuDvw7", validTimestamp, user2FirstSig, deployer
        );
        uint256 TreasuryBalance4 = address(deployer).balance;
        vm.stopPrank();
        assertEqUint(TreasuryBalance4 - TreasuryBalance3, 300000000000000);
    }
}
