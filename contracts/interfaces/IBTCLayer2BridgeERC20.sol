// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

interface IBTCLayer2BridgeERC20 {
    function addERC20TokenWrapped(string memory _name, string memory _symbol, uint8 _decimals, uint256 _cap) external returns(address);
    function mintERC20Token(bytes32 txHash, address token, address to, uint256 amount) external;
    function burnERC20Token(address sender, address token, uint256 amount) external;
    function allERC20TokenAddressLength() external view returns(uint256);
    function allERC20TxHashLength() external view returns(uint256);
    function userERC20MintTxHashLength(address user) external view returns(uint256);
    function setBlackListERC20Token(address token, address account, bool state) external;
}