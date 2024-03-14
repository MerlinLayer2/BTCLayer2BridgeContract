// SPDX-License-Identifier: GPL-3.0
// Implementation of permit based on https://github.com/WETH10/WETH10/blob/main/contracts/WETH10.sol
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract ERC20TokenWrapped is ERC20Permit, ERC20Capped {
    // PolygonZkEVM Bridge address
    address public immutable bridgeAddress;

    // Decimals
    uint8 private immutable _decimals;

    string public constant version = "1.2.0";

    // Blacklist
    mapping(address => bool) public isBlackListed;

    event SetBlackList(address account, bool state);

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
        uint8 __decimals,
        uint256 __cap
    ) ERC20(name, symbol) ERC20Permit(name) ERC20Capped(__cap){
        bridgeAddress = msg.sender;
        _decimals = __decimals;
    }

    function mint(address to, uint256 value) external onlyBridge {
        _mint(to, value);
    }

    // Notice that is not require to approve wrapped tokens to use the bridge
    function burn(address account, uint256 value) external onlyBridge {
        require(!isBlack(account), "account is in blackList");
        _burn(account, value);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _update(address from, address to, uint256 value) override(ERC20, ERC20Capped) internal virtual {
        require(!isBlack(from), "from is in blackList");
        ERC20Capped._update(from, to, value);
    }

    function setBlackList(address account, bool state) external onlyBridge {
        isBlackListed[account] = state;
        emit SetBlackList(account, state);
    }

    function isBlack(address account) public view returns (bool) {
        return isBlackListed[account];
    }
}
