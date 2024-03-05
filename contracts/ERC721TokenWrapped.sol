// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721TokenWrapped is ERC721Enumerable {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;
    string private _baseTokenURI;

    struct TokenId {
        uint256 tokenId;
        bool isUsed;
    }

    mapping(string => TokenId) public mpInscriptionId2TokenId;
    mapping(uint256 => string) public mpTokenId2InscriptionId;

    modifier onlyBridge() {
        require(
            msg.sender == bridgeAddress,
            "TokenWrapped::onlyBridge: Not BTCLayer2Bridge"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        bridgeAddress = msg.sender;
        _baseTokenURI = baseTokenURI;
    }

    function mint(address to, uint256 tokenId, string memory inscriptionId) external onlyBridge {
        //adjust exist
        require(bytes(mpTokenId2InscriptionId[tokenId]).length <= 0, "tokenId is repeat");
        require(mpInscriptionId2TokenId[inscriptionId].isUsed == false, "inscriptionId is repeat");

        mpInscriptionId2TokenId[inscriptionId] = TokenId(tokenId, true);
        mpTokenId2InscriptionId[tokenId] = inscriptionId;

        _mint(to, tokenId);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(address sender, uint256 tokenId) external onlyBridge returns (string memory){
        require(_ownerOf(tokenId) == sender, "Illegal permissions");
        string memory inscriptionId = mpTokenId2InscriptionId[tokenId];

        //adjust exist
        delete mpInscriptionId2TokenId[inscriptionId];
        delete mpTokenId2InscriptionId[tokenId];

        _burn(tokenId);
        return inscriptionId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) external onlyBridge {
        _baseTokenURI = newBaseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        require(bytes(mpTokenId2InscriptionId[tokenId]).length > 0, "tokenId is not exist");

        string memory inscriptionId = mpTokenId2InscriptionId[tokenId];
        return bytes(_baseTokenURI).length > 0 ? string.concat(_baseTokenURI, inscriptionId) : "";
    }
}
