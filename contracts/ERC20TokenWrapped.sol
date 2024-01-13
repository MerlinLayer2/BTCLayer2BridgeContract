// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ERC20TokenWrapped is ERC20Permit {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;

    // Decimals
    uint8 private immutable _decimals;

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
        uint8 __decimals
    ) ERC20(name, symbol) ERC20Permit(name) {
        bridgeAddress = msg.sender;
        _decimals = __decimals;
    }

    function mint(address to, uint256 value) external onlyBridge {
        _mint(to, value);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(address account, uint256 value) external onlyBridge {
        _burn(account, value);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
