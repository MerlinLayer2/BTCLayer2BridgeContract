// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721TokenWrapped is ERC721Enumerable {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;
    string private _baseTokenURI;

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

    function mint(address to, uint256 tokenId) external onlyBridge {
        _mint(to, tokenId);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(uint256 tokenId) external onlyBridge {
        _burn(tokenId);
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
}
