// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTUtils is Initializable {
    event Minted(address indexed minter, address indexed referrer, uint256 indexed tokenId);

    struct NFTUtilStorage {
        mapping(address minter => bool) _minted;
        mapping(uint256 tokenId => uint256) _score;
        bool _lockStatus;
        uint256 _fee;
    }

    // keccak256(abi.encode(uint256(keccak256("1tx.storage.MintUtils")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant NFTUtilStorageLocation = 0x0cf9a3f242fc17cfbf64ada354432b2786d4347b3e18a8c7dc5ddfc0c83f3f00;

    function _getNFTUtilStorage() private pure returns (NFTUtilStorage storage $) {
        assembly {
            $.slot := NFTUtilStorageLocation
        }
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __NFTUtils_init(uint256 fee) internal onlyInitializing {
        __NFTUtils_init_unchained(fee);
    }

    function __NFTUtils_init_unchained(uint256 fee) internal onlyInitializing {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._fee = fee;
        $._lockStatus = true;
    }

    function _mintLogging(address minter, address referrer, uint256 tokenId) internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._minted[minter] = true;
        emit Minted(minter, referrer, tokenId);
    }

    function isMinted(address user) public view returns (bool) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._minted[user];
    }

    function dataValidCheck(
        address signer,
        address tokenOwner,
        uint256 tokenId,
        uint256 newScore,
        string memory newTokenURI,
        uint256 deadline,
        bytes memory sig
    ) public view returns (bool) {
        require(block.timestamp <= deadline, "Expired");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(tokenOwner, tokenId, newScore, newTokenURI, deadline))
            )
        );
        return SignatureChecker.isValidSignatureNow(signer, messageHash, sig);
    }

    function getScore(uint256 tokenId) public view returns (uint256) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._score[tokenId];
    }

    function _setScore(uint256 tokenId, uint256 score) internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._score[tokenId] = score;
    }

    function getLockStatus() public view returns (bool) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._lockStatus;
    }

    function _lock() internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._lockStatus = true;
    }

    function _unLock() internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._lockStatus = false;
    }

    function _setFee(uint256 newFee) internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._fee = newFee;
    }

    function getFee() public view returns (uint256) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._fee;
    }
}
