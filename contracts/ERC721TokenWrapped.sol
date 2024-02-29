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

    function mint(address to, uint256 inscriptionNumber, string memory inscriptionId) external onlyBridge {
        //adjust exist
        require(mpId2Number[inscriptionId]==0, "inscriptionId is repeat");
        require(string.length(mpNumber2Id[inscriptionNumber])==0, "inscriptionNumber is repeat");

        mpId2Number[inscriptionId] = inscriptionNumber;
        mpNumber2Id[inscriptionNumber] = inscriptionId;

        _safeMint(to, inscriptionNumber);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(address sender, uint256 inscriptionNumber) external onlyBridge returns(string memory){
        require(_ownerOf(inscriptionNumber) == sender, "Illegal permissions");
        require(string.length(mpNumber2Id[inscriptionNumber])>0, "inscriptionNumber is not exist");

        string memory inscriptionId = mpNumber2Id[inscriptionNumber];

        //adjust exist
        delete mpId2Number[inscriptionId];
        delete mpNumber2Id[inscriptionNumber];

        _burn(inscriptionNumber);
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

    function tokenURI(uint256 inscriptionNumber) public view override virtual returns (string memory) {
        string memory inscriptionId = mpNumber2Id[inscriptionNumber];
        return bytes(_baseTokenURI).length > 0 ? string.concat(_baseTokenURI, inscriptionId) : "";
    }
}
