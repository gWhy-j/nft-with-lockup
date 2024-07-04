// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./extensions/NFTUtils.sol";

contract AmIBased1tx is ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, NFTUtils {
    function initialize(address initialOwner) public initializer {
        __ERC721_init("TestToken", "TT");
        __Ownable_init(initialOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        // Call parent contracts' supportsInterface methods
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 amount)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        ERC721EnumerableUpgradeable._increaseBalance(account, amount);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        address previousOwner = ERC721EnumerableUpgradeable._update(to, tokenId, auth);
        if (isLocked() && previousOwner != address(0)) {
            revert("Transfer is not possible as it is still locked");
        }
        return previousOwner;
    }

    function amIBased(uint256 newScore, string memory newTokenURI, bytes memory sig, address referrer) public payable {
        require(!isMinted(msg.sender), "NFT already minted!");
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(msg.sender, newTokenId);
        _mintLogging(msg.sender, referrer, newTokenId);
        updateTokenInfo(newTokenId, newScore, newTokenURI, sig);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function setLock(bool lock) public onlyOwner {
        if (lock) {
            _lock();
        } else {
            _unLock();
        }
    }

    function updateTokenInfo(uint256 tokenId, uint256 newScore, string memory newTokenURI, bytes memory sig) public {
        require(dataValidCheck(owner(), newScore, newTokenURI, sig), "Invalid Signature");
        require(msg.sender == _requireOwned(tokenId), "Update available for only owner");
        _updateTokenInfo(tokenId, newScore, newTokenURI);
    }

    function _updateTokenInfo(uint256 tokenId, uint256 newScore, string memory newTokenURI) internal {
        _setScore(tokenId, newScore);
        _setTokenURI(tokenId, newTokenURI);
    }
}
