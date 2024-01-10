// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721TokenWrapped is ERC721 {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;

    modifier onlyBridge() {
        require(
            msg.sender == bridgeAddress,
            "TokenWrapped::onlyBridge: Not BTCLayer2Bridge"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        bridgeAddress = msg.sender;
    }

    function mint(address to, uint256 tokenId) external onlyBridge {
        _mint(to, tokenId);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(uint256 tokenId) external onlyBridge {
        _burn(tokenId);
    }
}
