// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {IAmBased} from "../src/IAmBased.sol";

// forge test --match-contract MainnetIAmBasedTest -vvv --gas-report

contract MainnetIAmBasedTest is Test {
    IAmBased public iAmBased = IAmBased(address(0xA760d1CA9e5cB6333BaC7619A8765595829176f0));
    uint256 mainnetFork;
    address user1 = address(0x1d8e5a1c88aCfccED410f1a7A89237BA11FaF02F);
    address user2 = address(0x2300Ed1feECD5Fe7D1913DD3eB4699aC05D16122);
    address payable deployer = payable(address(0xba6419c1f65F447eF6f19942bBee3BF281C6c521)); // deployer = eventOwner in test env.
    address payable owner = payable(address(0x77bbFD2d630A9123Ae5da78a7Af8856983223c8A));
    uint256 validTimestamp = 1770186688;
    uint256 invalidTimestamp = 1710187779;

    bytes user1FirstSig =
        hex"4f969902207fca1b804e302e716925e074294bf8f0e2a0e1536eb59d1d02e92421b9e7d89727bca4b144798a63dbb041c36607a6fd016d4b020fa20bd6ad85711b";
    bytes user1SecondSig =
        hex"791528291c00f22cb76d5781603f6871468fa690a5171eb707a4b11c7658e89b53def49f65b3c7ef06a83574b47b06ab67b8d91c3f35e26802146cdee2c6a5ed1c";
    bytes user1InvalidSig =
        hex"ea43b679fd7c76e5a89f5f8946837478f2dc7476e438b505b6ec3f910abf0c406b1e40e39eed3afe4f44a252a3c3629d08c5159e14af42b59b14a7d1a76a3a441c";
    bytes user2FirstSig =
        hex"d08c7fd1bbc6cc69d121f2eef8472fa4b952bc6cdec96626650b0162bb6255ee503ae33fb64947a5143ef76ce50017bad047d05d74bed97a11fbd84dc454b7391b";
    bytes user2SecondSig =
        hex"b4a7c823ef70399766559567bf84a6687a5dd22a2aeb7bcfc58fa4a165cf87fe0fc3937870677cef9f9f1c7b80e9952d6c9448af4c316cbd037f87b880b4248d1c";
    bytes user2InvalidSig =
        hex"9517cc513c8cf0543bb0a9dcf2f415c3ce8032534ba9a0de77818836c2c3ce7477575d1f49a74d403b405256dee73a6a9ea231873b160bb364c046b1d2f95dc01b";

    function setUp() public {
        mainnetFork = vm.createSelectFork("https://base-mainnet.g.alchemy.com/v2/evugMWDogG8GHmBCVjrolsEMUMmbnsbH");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.startPrank(deployer);
        vm.label(address(iAmBased), "IAmBased");
        vm.label(address(user1), "User1");
        vm.label(address(user2), "User2");
        vm.stopPrank();
    }

    function test_SupportsInterface() public view {
        require(iAmBased.supportsInterface(bytes4(0x780e9d63)));
        require(iAmBased.supportsInterface(bytes4(0x49064906)));
    }

    function test_UnLock() public {
        vm.prank(owner);
        iAmBased.setLock(false);
        assertEq(iAmBased.getLockStatus(), false);
    }

    function test_Lock() public {
        vm.prank(owner);
        iAmBased.setLock(true);
        assertEq(iAmBased.getLockStatus(), true);
    }

    function testFail_UnLock() public {
        iAmBased.setLock(false);
    }

    function test_DataValidCheck() public {
        vm.prank(user1);
        iAmBased.amIBased{value: 200000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        require(
            iAmBased.dataValidCheck(
                user1, 0, 100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig
            )
        );
    }

    function testFail_DataValidCheck() public {
        vm.prank(user1);
        iAmBased.amIBased{value: 200000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        require(
            iAmBased.dataValidCheck(
                user1, 0, 200, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig
            )
        );
    }

    function test_Mint() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(owner).balance;
        uint256 newTokenId = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(owner).balance;
        uint256 score = iAmBased.getScore(newTokenId);
        string memory tokenURI = iAmBased.tokenURI(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        assertEq(tokenURI, "https://summer.1tx.network/api/iambased/1");
        assertEq(iAmBased.balanceOf(user1), 1);
        assertEq(iAmBased.totalSupply(), 1);
        assertEq(iAmBased.isMinted(user1), true);
        vm.stopPrank();
    }

    function test_MintInsufficientBalance() public {
        vm.startPrank(user1);
        vm.expectRevert("Insufficient balance");
        iAmBased.amIBased{value: 100000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        vm.stopPrank();
    }

    function test_MintInvalidSig() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid Signature");
        iAmBased.amIBased{value: 200000000000000}(
            150, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        vm.stopPrank();
    }

    function test_MintAndTransfer() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(owner).balance;
        uint256 newTokenId = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(owner).balance;
        uint256 score = iAmBased.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        vm.stopPrank();
        assertEq(iAmBased.balanceOf(user1), 1);
        assertEq(iAmBased.balanceOf(deployer), 0);

        vm.prank(owner);
        iAmBased.setLock(false);

        vm.prank(user1);
        iAmBased.transferFrom(user1, deployer, newTokenId);
        assertEq(iAmBased.balanceOf(user1), 0);
        assertEq(iAmBased.balanceOf(deployer), 1);

        assertEq(iAmBased.ownerOf(newTokenId), deployer);
    }

    function testFail_MintAndTransfer() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(owner).balance;
        uint256 newTokenId = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(owner).balance;
        uint256 score = iAmBased.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);

        iAmBased.transferFrom(user1, deployer, newTokenId);
        vm.stopPrank();
    }

    function test_MintAndSafeTransferFrom() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(owner).balance;
        uint256 newTokenId = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(owner).balance;
        uint256 score = iAmBased.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);
        vm.stopPrank();

        vm.prank(owner);
        iAmBased.setLock(false);

        vm.prank(user1);
        iAmBased.safeTransferFrom(user1, deployer, newTokenId);

        assertEq(iAmBased.ownerOf(newTokenId), deployer);
    }

    function testFail_MintAndSafeTransferFrom() public {
        vm.startPrank(user1);
        uint256 initialTreasuryBalance = address(owner).balance;
        uint256 newTokenId = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 afterTreasuryBalance = address(owner).balance;
        uint256 score = iAmBased.getScore(newTokenId);
        assertEqUint(score, 100);
        assertEqUint(afterTreasuryBalance - initialTreasuryBalance, 200000000000000);

        iAmBased.safeTransferFrom(user1, deployer, newTokenId);
        vm.stopPrank();
    }

    function testFail_MintTwice() public {
        vm.prank(user1);
        uint256 firstNFT = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(owner);
        iAmBased.setLock(false);

        vm.prank(user1);
        iAmBased.transferFrom(user1, deployer, firstNFT);

        vm.prank(user1);
        iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
    }

    function test_SetTokenURIFromValidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        iAmBased.updateTokenInfo(
            firstNFT, 200, "https://summer.1tx.network/api/iambased/", validTimestamp, user1SecondSig
        );
    }

    function test_SetTokenURIFromInvalidOwner() public {
        vm.prank(user1);
        uint256 firstNFT = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user2);
        iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user2FirstSig, deployer
        );

        vm.prank(user2);
        vm.expectRevert("Update available for token owner");
        iAmBased.updateTokenInfo(
            firstNFT, 200, "https://summer.1tx.network/api/iambased/", validTimestamp, user1SecondSig
        );
    }

    function test_SetTokenURIWithInvalidScore() public {
        vm.prank(user1);
        uint256 firstNFT = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        vm.expectRevert("Invalid Signature");
        iAmBased.updateTokenInfo(
            firstNFT, 250, "https://summer.1tx.network/api/iambased/", validTimestamp, user1SecondSig
        );
    }

    function test_SetTokenURIWithInvalidTimestamp() public {
        vm.prank(user1);
        uint256 firstNFT = iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );

        vm.prank(user1);
        vm.expectRevert("Expired");
        iAmBased.updateTokenInfo(
            firstNFT, 200, "https://summer.1tx.network/api/iambased/", invalidTimestamp, user1InvalidSig
        );
    }

    function testFail_ChangeFee() public {
        vm.prank(user1);
        iAmBased.setFee(300000000000000);
    }

    function test_ChangeFee() public {
        vm.startPrank(user1);
        uint256 TreasuryBalance1 = address(owner).balance;
        iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        uint256 TreasuryBalance2 = address(owner).balance;
        vm.stopPrank();
        assertEqUint(TreasuryBalance2 - TreasuryBalance1, 200000000000000);

        vm.prank(owner);
        iAmBased.setFee(300000000000000);
        assertEq(iAmBased.getFee(), 300000000000000);

        vm.startPrank(user2);
        uint256 TreasuryBalance3 = address(owner).balance;
        iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user2FirstSig, deployer
        );
        uint256 TreasuryBalance4 = address(owner).balance;
        vm.stopPrank();
        assertEqUint(TreasuryBalance4 - TreasuryBalance3, 300000000000000);
    }

    function test_ChangeSigner() public {
        vm.startPrank(owner);
        iAmBased.setSigner(user1);
        vm.stopPrank();
    }

    function testFail_ChangeSigner() public {
        vm.startPrank(deployer);
        iAmBased.setSigner(user1);
        vm.stopPrank();
    }

    function testFail_ChangeSignerAndMint() public {
        vm.startPrank(owner);
        iAmBased.setSigner(user1);
        vm.stopPrank();
        vm.startPrank(user1);
        iAmBased.amIBased{value: 500000000000000}(
            100, "https://summer.1tx.network/api/iambased/", validTimestamp, user1FirstSig, deployer
        );
        vm.stopPrank();
    }
}
