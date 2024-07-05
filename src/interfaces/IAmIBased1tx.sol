// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IAmIBased1tx {
    error ERC721EnumerableForbiddenBatchMint();
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);
    error ERC721InvalidOwner(address owner);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InvalidSender(address sender);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721OutOfBoundsIndex(address owner, uint256 index);
    error InvalidInitialization();
    error NotInitializing();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event Initialized(uint64 version);
    event Locked(uint256 tokenId);
    event MetadataUpdate(uint256 _tokenId);
    event Minted(address indexed minter, address indexed referrer, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Unlocked(uint256 tokenId);

    function amIBased(uint256 newScore, string memory newTokenURI, bytes memory sig, address referrer)
        external
        payable
        returns (uint256);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function dataValidCheck(address signer, uint256 newScore, string memory newTokenURI, bytes memory sig)
        external
        view
        returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function getFee() external view returns (uint256);
    function getLockStatus() external view returns (bool);
    function getScore(uint256 tokenId) external view returns (uint256);
    function initialize(address initialOwner, uint256 fee) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function isMinted(address user) external view returns (bool);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function renounceOwnership() external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setLock(bool lock) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function transferOwnership(address newOwner) external;
    function updateTokenInfo(uint256 tokenId, uint256 newScore, string memory newTokenURI, bytes memory sig) external;
}
