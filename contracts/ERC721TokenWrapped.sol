// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721TokenWrapped is ERC721Enumerable {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;
    string private _baseTokenURI;

    mapping(string => uint256) public mpId2Number;
    mapping(uint256 => string) public mpNumber2Id;

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

    function mint(address to, uint256 number, string memory inscriptionId) external onlyBridge {
        //adjust exist
        require(bytes(mpNumber2Id[number]).length<=0, "number is repeat");
        require(mpId2Number[inscriptionId]==0 && inscriptionId != mpNumber2Id[0], "inscriptionId is repeat");

        mpId2Number[inscriptionId] = number;
        mpNumber2Id[number] = inscriptionId;

        _mint(to, number);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(address sender, uint256 number) external onlyBridge returns(string memory){
        require(_ownerOf(number) == sender, "Illegal permissions");
        require(bytes(mpNumber2Id[number]).length>0, "number is not exist");

        string memory inscriptionId = mpNumber2Id[number];

        //adjust exist
        delete mpId2Number[inscriptionId];
        delete mpNumber2Id[number];

        _burn(number);
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

    function tokenURI(uint256 number) public view override virtual returns (string memory) {
        string memory inscriptionId = mpNumber2Id[number];
        return bytes(_baseTokenURI).length > 0 ? string.concat(_baseTokenURI, inscriptionId) : "";
    }
}
