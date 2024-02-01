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

    mapping(bytes => uint256) public mpId2Number;
    mapping(uint256 => bytes) public mpNumber2Id;

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
    function tokenURI(uint256 inscriptionNumber) public view virtual override returns (string memory) {
        require(inscriptionNumber>=1, "This inscriptionNumber is not exist");
        return super.tokenURI(mpNumber2Id[inscriptionNumber]);
    }

    function batchMintERC721Token(bytes32 txHash, address token, address to, string[] memory inscriptionIds, uint256[] memory inscriptionNumbers) external onlyBridge {
        require(inscriptionIds.length == inscriptionNumbers.length, "length is not match.");
        require(inscriptionIds.length <= 100, "inscriptionIds's length is too many");

        require(erc721TxHashUnlocked[txHash] == false, "Transaction has been executed");
        erc721TxHashUnlocked[txHash] = true;
        require(erc721TokenInfoSupported[token], "This token is not supported");
        allERC721TxHash.push(txHash);

        userERC721MintTxHash[to].push(txHash);

        //check param is repeat or already exists（inscriptionIds + inscriptionNumbers）
        mapping(uint256 => bool) memory mapNumber;
        mapping(string => bool) memory mapId;
        for (uint16 i=0; i<inscriptionNumbers.length; i++) {
            uint256 inscriptionNumber = inscriptionNumbers[i];
            string memory inscriptionId = inscriptionIds[i];

            bool paraRepeat = mapNumber[inscriptionNumber] || mapId[inscriptionId];
            require(!paraRepeat, "tokenId to mint is repeat!");

            bool already = mpNumber2Id[inscriptionNumber] || mpId2Number[inscriptionId];
            require(!already, "tokenId to mint already exists!");
         }

        //batch mint
        for (uint16 i=0; i<inscriptionNumbers.length; i++) {
            uint256 inscriptionNumber = inscriptionNumbers[i];
            string memory inscriptionId = inscriptionIds[i];

            mpId2Number[inscriptionId] = inscriptionNumber;
            mpNumber2Id[inscriptionNumber] = inscriptionId;

            ERC721TokenWrapped(token).mint(to, inscriptionNumber);
        }
    }

    function batchBurnERC721Token(address sender, address token, uint256[] memory inscriptionNumbers) external onlyBridge returns(string[] memory burnInscriptionIds) {
        require(erc721TokenInfoSupported[token], "This token is not supported");
        require(inscriptionNumbers.length <= 100, "inscriptionNumbers's length is too many");

        //check param is repeat or already exists（inscriptionIds + inscriptionNumbers）
        mapping(uint256 => bool) memory mapNumber;
        for (uint16 i=0; i<inscriptionNumbers.length; i++) {
            uint256 inscriptionNumber = inscriptionNumbers[i];
            require(ERC721TokenWrapped(token).ownerOf(inscriptionNumber) == sender, "Illegal permissions");

            string memory paraRepeat = mapNumber[inscriptionNumber];
            require(!paraRepeat, "tokenId to burn is repeat!");

            uint256 already = mpNumber2Id[inscriptionNumber];
            require(already, "tokenId to burn not exists!");
        }

        //batch burn
        for (uint16 i=0; i<inscriptionNumbers.length; i++) {
            uint256 inscriptionNumber = inscriptionNumbers[i];
            uint256 inscriptionId = mpNumber2Id[inscriptionNumber];

            delete mpId2Number[inscriptionId];
            delete mpNumber2Id[inscriptionNumber];

            burnInscriptionIds.push(inscriptionId);
            ERC721TokenWrapped(token).burn(inscriptionNumber);
        }

        return burnInscriptionIds;
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