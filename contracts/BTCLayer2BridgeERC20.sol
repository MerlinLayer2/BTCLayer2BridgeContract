// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC20TokenWrapped.sol";

contract BTCLayer2BridgeERC20 is OwnableUpgradeable {
    address public bridgeAddress;
    mapping(bytes32 => address) public erc20TokenInfoToWrappedToken;
    mapping(address => bool) public erc20TokenInfoSupported;
    address[] public allERC20TokenAddress;
    mapping(bytes32 => bool) public erc20TxHashUnlocked;
    bytes32[] public allERC20TxHash;
    mapping(address => bytes32[]) public userERC20MintTxHash;

    string public constant version = "1.2.0";

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

    function addERC20TokenWrapped(string memory _name, string memory _symbol, uint8 _decimals, uint256 _cap) external onlyBridge returns(address)  {
        bytes32 tokenInfoHash = keccak256(
            abi.encodePacked(_name, _symbol, _decimals, _cap)
        );
        address wrappedToken = erc20TokenInfoToWrappedToken[tokenInfoHash];
        require(wrappedToken == address(0), "The current token already exists");
        // Create a new wrapped erc20 using create2
        ERC20TokenWrapped newWrappedToken = (new ERC20TokenWrapped){
                salt: tokenInfoHash
            }(_name, _symbol, _decimals, _cap);
        // Create mappings
        address tokenWrappedAddress = address(newWrappedToken);
        erc20TokenInfoToWrappedToken[tokenInfoHash] = tokenWrappedAddress;
        erc20TokenInfoSupported[tokenWrappedAddress] = true;
        allERC20TokenAddress.push(tokenWrappedAddress);
        return tokenWrappedAddress;
    }

    function mintERC20Token(bytes32 txHash, address token, address to, uint256 amount) external onlyBridge {
        require(erc20TxHashUnlocked[txHash] == false, "Transaction has been executed");
        erc20TxHashUnlocked[txHash] = true;
        require(erc20TokenInfoSupported[token], "This token is not supported");
        allERC20TxHash.push(txHash);
        userERC20MintTxHash[to].push(txHash);
        ERC20TokenWrapped(token).mint(to, amount);
    }

    function burnERC20Token(address sender, address token, uint256 amount) external onlyBridge {
        require(erc20TokenInfoSupported[token], "This token is not supported");
        ERC20TokenWrapped(token).burn(sender, amount);
    }

    function allERC20TokenAddressLength() public view returns(uint256) {
        return allERC20TokenAddress.length;
    }

    function allERC20TxHashLength() public view returns(uint256) {
        return allERC20TxHash.length;
    }

    function userERC20MintTxHashLength(address user) public view returns(uint256) {
        return userERC20MintTxHash[user].length;
    }

    function setBlackListERC20Token(address token, address account, bool state) external onlyBridge{
        require(erc20TokenInfoSupported[token], "This token is not supported");
        ERC20TokenWrapped(token).setBlackList(account, state);
    }
}