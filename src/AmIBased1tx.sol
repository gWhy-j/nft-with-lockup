// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./extensions/NFTUtils.sol";

contract AmIBased1tx is ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, NFTUtils {
    function initialize(address initialOwner, uint256 fee) public initializer {
        __ERC721_init("TestToken", "TT");
        __Ownable_init(initialOwner);
        __NFTUtils_init(fee);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        // Call parent contracts' supportsInterface methods
        return ERC721URIStorageUpgradeable.supportsInterface(interfaceId)
            || ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
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

        // If the previous owner is not the zero address, it's a transfer, so revert if locked
        if (getLockStatus() && previousOwner != address(0)) {
            revert("Transfer is not possible as it is still locked");
        }
        return previousOwner;
    }

    function amIBased(uint256 newScore, string memory newTokenURI, uint256 deadline, bytes memory sig, address referrer)
        public
        payable
        returns (uint256)
    {
        require(!isMinted(msg.sender), "NFT already minted!");
        uint256 feeAmount = getFee();
        require(msg.value >= feeAmount, "Insufficient balance");

        uint256 newTokenId = totalSupply() + 1;
        _safeMint(msg.sender, newTokenId);
        _mintLogging(msg.sender, referrer, newTokenId);
        initialTokenInfo(newTokenId, newScore, newTokenURI, deadline, sig);

        // Send fee amount to the owner() address
        (bool sent,) = owner().call{value: feeAmount}("");
        require(sent, "Failed to send Ether");

        // Refund the remaining amount to the sender
        uint256 refundAmount = msg.value - feeAmount;
        if (refundAmount > 0) {
            (bool refunded,) = msg.sender.call{value: refundAmount}("");
            require(refunded, "Failed to refund Ether");
        }

        return (newTokenId);
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
            for (uint256 i = 1; i <= totalSupply(); i++) {
                emit Unlocked(i);
            }
        }
    }

    function setFee(uint256 fee) public onlyOwner {
        _setFee(fee);
    }

    function initialTokenInfo(
        uint256 tokenId,
        uint256 newScore,
        string memory newTokenURI,
        uint256 deadline,
        bytes memory sig
    ) internal {
        require(msg.sender == _requireOwned(tokenId), "Update available for token owner");
        require(
            dataValidCheck(address(owner()), msg.sender, 0, newScore, newTokenURI, deadline, sig), "Invalid Signature"
        );
        _updateTokenInfo(tokenId, newScore, newTokenURI);
    }

    function updateTokenInfo(
        uint256 tokenId,
        uint256 newScore,
        string memory newTokenURI,
        uint256 deadline,
        bytes memory sig
    ) public {
        require(msg.sender == _requireOwned(tokenId), "Update available for token owner");
        require(
            dataValidCheck(address(owner()), msg.sender, tokenId, newScore, newTokenURI, deadline, sig),
            "Invalid Signature"
        );
        _updateTokenInfo(tokenId, newScore, newTokenURI);
    }

    function _updateTokenInfo(uint256 tokenId, uint256 newScore, string memory newTokenURI) internal {
        _setScore(tokenId, newScore);
        _setTokenURI(tokenId, newTokenURI);
    }
}
