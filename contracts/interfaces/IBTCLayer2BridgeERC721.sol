// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

interface IBTCLayer2BridgeERC721 {
    function addERC721TokenWrapped(string memory _name, string memory _symbol, string memory _baseURI) external returns(address);
    function setBaseURI(address token, string calldata newBaseTokenURI) external;
    function tokenURI(address token, uint256 inscriptionNumber) external returns (string memory);
    function batchMintERC721Token(bytes32 txHash, address token, address to, string[] memory inscriptionIds, uint256[] memory inscriptionNumbers) external;
    function batchBurnERC721Token(address sender, address token, uint256[] memory inscriptionNumbers) external returns(string[] memory burnInscriptionIds);
    function allERC721TokenAddressLength() external view returns(uint256);
    function allERC721TxHashLength() external view returns(uint256);
    function userERC721MintTxHashLength(address user) external view returns(uint256);
}