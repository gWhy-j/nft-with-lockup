// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract NFTUtils {
    event Minted(address indexed minter, address indexed referrer, uint256 indexed tokenId);
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    struct NFTUtilStorage {
        mapping(address minter => bool) _minted;
        mapping(uint256 tokenId => uint256) _score;
        bool _isLocked;
    }

    // keccak256(abi.encode(uint256(keccak256("1tx.storage.MintUtils")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant NFTUtilStorageLocation = 0x0cf9a3f242fc17cfbf64ada354432b2786d4347b3e18a8c7dc5ddfc0c83f3f00;

    function _getNFTUtilStorage() private pure returns (NFTUtilStorage storage $) {
        assembly {
            $.slot := NFTUtilStorageLocation
        }
    }

    function _mintLogging(address minter, address referrer, uint256 tokenId) internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._minted[minter] = true;
        emit Minted(minter, referrer, tokenId);
        if ($._isLocked) {
            emit Locked(tokenId);
        }
    }

    function isMinted(address user) public view returns (bool) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._minted[user];
    }

    function dataValidCheck(address signer, uint256 newScore, string memory newTokenURI, bytes memory sig)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(newScore, newTokenURI));
        return SignatureChecker.isValidSignatureNow(signer, messageHash, sig);
    }

    function _setScore(uint256 tokenId, uint256 score) internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._score[tokenId] = score;
    }

    function isLocked() public view returns (bool) {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        return $._isLocked;
    }

    function _lock() internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._isLocked = true;
    }

    function _unLock() internal {
        NFTUtilStorage storage $ = _getNFTUtilStorage();
        $._isLocked = false;
    }
}
