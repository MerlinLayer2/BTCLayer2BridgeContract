// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC721TokenWrapped.sol";

contract BTCLayer2BridgeERC721 is OwnableUpgradeable {
    address public bridgeAddress;
    mapping(bytes32 => address) public erc721TokenInfoToWrappedToken;
    mapping(address => bool) public erc721TokenInfoSupported;
    address[] public allERC721TokenAddress;
    mapping(bytes32 => bool) public erc721TxHashUnlocked;
    bytes32[] public allERC721TxHash;
    mapping(address => bytes32[]) public userERC721MintTxHash;

    mapping(uint256 => bytes) public mpId2Number;
    mapping(bytes => uint256) public mpNumber2Id;

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    modifier onlyBridge() {
        require(
            msg.sender == bridgeAddress,
            "TokenWrapped::onlyBridge: Not BTCLayer2Bridge"
        );
        _;
    }

    function initialize(
        address _initialOwner,
        address _bridgeAddress
    ) external onlyValidAddress(_initialOwner)
    onlyValidAddress(_bridgeAddress) virtual initializer {
        bridgeAddress = _bridgeAddress;
        // Initialize OZ contracts
        __Ownable_init_unchained(_initialOwner);
    }

    function addERC721TokenWrapped(string memory _name, string memory _symbol, string memory _baseURI) external onlyBridge returns(address) {
        bytes32 tokenInfoHash = keccak256(
            abi.encodePacked(_name, _symbol, _baseURI)
        );
        address wrappedToken = erc721TokenInfoToWrappedToken[tokenInfoHash];
        require(wrappedToken == address(0), "The current token already exists");
        // Create a new wrapped erc20 using create2
        ERC721TokenWrapped newWrappedToken = (new ERC721TokenWrapped){
                salt: tokenInfoHash
            }(_name, _symbol, _baseURI);
        // Create mappings
        address tokenWrappedAddress = address(newWrappedToken);
        erc721TokenInfoToWrappedToken[tokenInfoHash] = tokenWrappedAddress;
        erc721TokenInfoSupported[tokenWrappedAddress] = true;
        allERC721TokenAddress.push(tokenWrappedAddress);
        return tokenWrappedAddress;
    }

    function setBaseURI(address token, string calldata newBaseTokenURI) external onlyBridge {
        ERC721TokenWrapped(token).setBaseURI(newBaseTokenURI);
    }

    //tokenURI: id->number->tokenURI(number)
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        inscriptionNumber = tokenId;
        require(mpNumber2Id[inscriptionNumber], "This inscriptionNumber is not exist");

        inscriptionId = mpNumber2Id[inscriptionNumber];
        return super.tokenURI(inscriptionId);
    }

    function mintERC721Token(bytes32 txHash, address token, address to, uint256 inscriptionId, bytes inscriptionNumber) external onlyBridge {
        require(erc721TxHashUnlocked[txHash] == false, "Transaction has been executed");
        erc721TxHashUnlocked[txHash] = true;
        require(erc721TokenInfoSupported[token], "This token is not supported");
        allERC721TxHash.push(txHash);

        tokenId = inscriptionNumber;
        mpId2Number[inscriptionId] = inscriptionNumber;
        mpNumber2Id[inscriptionNumber] = inscriptionId;

        userERC721MintTxHash[to].push(txHash);
        ERC721TokenWrapped(token).mint(to, tokenId);
    }

    function burnERC721Token(address sender, address token, uint256 tokenId) external onlyBridge {
        require(erc721TokenInfoSupported[token], "This token is not supported");
        require(ERC721TokenWrapped(token).ownerOf(tokenId) == sender, "Illegal permissions");

        require(erc721TokenInfoSupported[tokenId], "This inscription id is not supported");

        ERC721TokenWrapped(token).burn(tokenId);
    }

    function burnERC721TokenByInscriptionId(address sender, address token, uint256 inscriptionId) external onlyBridge {
        require(erc721TokenInfoSupported[token], "This token is not supported");
        require(ERC721TokenWrapped(token).ownerOf(tokenId) == sender, "Illegal permissions");

        require(erc721TokenInfoSupported[inscriptionId], "This inscription id is not supported");
        tokenId = mpId2Number[inscriptionNumber];

        ERC721TokenWrapped(token).burn(tokenId);
    }

    function allERC721TokenAddressLength() public view returns(uint256) {
        return allERC721TokenAddress.length;
    }

    function allERC721TxHashLength() public view returns(uint256) {
        return allERC721TxHash.length;
    }

    function userERC721MintTxHashLength(address user) public view returns(uint256) {
        return userERC721MintTxHash[user].length;
    }
}