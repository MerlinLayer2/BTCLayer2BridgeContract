// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC20TokenWrapped.sol";
import "./ERC721TokenWrapped.sol";

contract BTCLayer2Bridge is OwnableUpgradeable {
    address public superAdminAddress;
    address public normalAdminAddress;
    address[] public unlockTokenAdminAddressList;
    mapping(address => bool) public unlockTokenAdminAddressSupported;
    mapping(bytes32 => address) public erc20TokenInfoToWrappedToken;
    mapping(address => bool) public erc20TokenInfoSupported;
    address[] public allERC20TokenAddress;
    mapping(bytes32 => bool) public erc20TxHashUnlocked;
    bytes32[] public allERC20TxHash;
    mapping(address => bytes32[]) public userERC20MintTxHash;

    mapping(bytes32 => address) public erc721TokenInfoToWrappedToken;
    mapping(address => bool) public erc721TokenInfoSupported;
    address[] public allERC721TokenAddress;
    mapping(bytes32 => bool) public erc721TxHashUnlocked;
    bytes32[] public allERC721TxHash;
    mapping(address => bytes32[]) public userERC721MintTxHash;

    // nativeToken
    mapping(bytes32 => bool) public nativeTokenTxHashUnlocked;
    bytes32[] public allNativeTokenTxHash;
    mapping(address => bytes32[]) public userNativeTokenMintTxHash;

    uint256 public bridgeFee;
    address public feeAddress;

    event SuperAdminAddressChanged(
        address oldAddress,
        address newAddress
    );

    event AddERC20TokenWrapped(
        address tokenWrappedAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    event MintERC20Token(
        bytes32 txHash,
        address token,
        address account,
        uint256 amount
    );

    event BurnERC20Token(
        address token,
        address account,
        uint256 amount
    );

    event AddERC721TokenWrapped(
        address tokenWrappedAddress,
        string name,
        string symbol
    );

    event MintERC721Token(
        bytes32 txHash,
        address token,
        address account,
        uint256 tokenId
    );

    event BurnERC721Token(
        address token,
        address account,
        uint256 tokenId
    );

    event UnlockNativeToken(
        bytes32 txHash,
        address account,
        uint256 amount
    );

    event LockNativeToken(
        address account,
        uint256 amount
    );

    error EtherTransferFailed();

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    receive() external payable {}
    
    function initialize(
        address _initialOwner,
        address _superAdminAddress,
        address _normalAdminAddress,
        uint256  _bridgeFee,
        address _feeAddress
    ) external onlyValidAddress(_initialOwner)
    onlyValidAddress(_superAdminAddress)
    onlyValidAddress(_normalAdminAddress)
    onlyValidAddress(_feeAddress) virtual initializer {
        superAdminAddress = _superAdminAddress;
        normalAdminAddress = _normalAdminAddress;
        bridgeFee = _bridgeFee;
        feeAddress = _feeAddress;
        // Initialize OZ contracts
        __Ownable_init_unchained(_initialOwner);
    }

    function setSuperAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress, "Illegal permissions");
        address oldSuperAdminAddress = superAdminAddress;
        superAdminAddress = _account;
        emit SuperAdminAddressChanged(oldSuperAdminAddress, _account);
    }

    function setNormalAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress, "Illegal permissions");
        normalAdminAddress = _account;
    }

    function addUnlockTokenAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        require(unlockTokenAdminAddressSupported[_account] == false, "Current address has been added");
        unlockTokenAdminAddressList.push(_account);
        unlockTokenAdminAddressSupported[_account] = true;
    }

    function addERC20TokenWrapped(string memory _name, string memory _symbol, uint8 _decimals) public returns(address) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        bytes32 tokenInfoHash = keccak256(
            abi.encodePacked(_name, _symbol, _decimals)
        );
        address wrappedToken = erc20TokenInfoToWrappedToken[tokenInfoHash];
        require(wrappedToken == address(0), "The current token already exists");
        // Create a new wrapped erc20 using create2
        ERC20TokenWrapped newWrappedToken = (new ERC20TokenWrapped){
                salt: tokenInfoHash
            }(_name, _symbol, _decimals);
        // Create mappings
        address tokenWrappedAddress = address(newWrappedToken);
        erc20TokenInfoToWrappedToken[tokenInfoHash] = tokenWrappedAddress;
        erc20TokenInfoSupported[tokenWrappedAddress] = true;
        allERC20TokenAddress.push(tokenWrappedAddress);
        emit AddERC20TokenWrapped(tokenWrappedAddress, _name, _symbol, _decimals);
        return tokenWrappedAddress;
    }

    function mintERC20Token(bytes32 txHash, address token, address to, uint256 amount) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(erc20TxHashUnlocked[txHash] == false, "Transaction has been executed");
        erc20TxHashUnlocked[txHash] = true;
        require(erc20TokenInfoSupported[token], "This token is not supported");
        ERC20TokenWrapped(token).mint(to, amount);
        allERC20TxHash.push(txHash);
        userERC20MintTxHash[to].push(txHash);
        emit MintERC20Token(txHash, token, to, amount);
    }

    function burnERC20Token(address token, uint256 amount) public payable {
        require(msg.value == bridgeFee, "The bridgeFee is incorrect");
        require(erc20TokenInfoSupported[token], "This token is not supported");
        ERC20TokenWrapped(token).burn(msg.sender, amount);
        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit BurnERC20Token(token, msg.sender, amount);
    }

    function addERC721TokenWrapped(string memory _name, string memory _symbol) public {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        bytes32 tokenInfoHash = keccak256(
            abi.encodePacked(_name, _symbol)
        );
        address wrappedToken = erc721TokenInfoToWrappedToken[tokenInfoHash];
        require(wrappedToken == address(0), "The current token already exists");
        // Create a new wrapped erc20 using create2
        ERC721TokenWrapped newWrappedToken = (new ERC721TokenWrapped){
                salt: tokenInfoHash
            }(_name, _symbol);
        // Create mappings
        address tokenWrappedAddress = address(newWrappedToken);
        erc721TokenInfoToWrappedToken[tokenInfoHash] = tokenWrappedAddress;
        erc721TokenInfoSupported[tokenWrappedAddress] = true;
        allERC721TokenAddress.push(tokenWrappedAddress);
        emit AddERC721TokenWrapped(tokenWrappedAddress, _name, _symbol);
    }

    function mintERC721Token(bytes32 txHash, address token, address to, uint256 tokenId) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(erc721TxHashUnlocked[txHash] == false, "Transaction has been executed");
        erc721TxHashUnlocked[txHash] = true;
        require(erc721TokenInfoSupported[token], "This token is not supported");
        ERC721TokenWrapped(token).mint(to, tokenId);
        allERC721TxHash.push(txHash);
        userERC721MintTxHash[to].push(txHash);
        emit MintERC721Token(txHash, token, to, tokenId);
    }

    function burnERC721Token(address token, uint256 tokenId) public payable {
        require(msg.value == bridgeFee, "The bridgeFee is incorrect");
        require(erc721TokenInfoSupported[token], "This token is not supported");
        require(ERC721TokenWrapped(token).ownerOf(tokenId) == msg.sender, "Illegal permissions");
        ERC721TokenWrapped(token).burn(tokenId);
        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit BurnERC721Token(token, msg.sender, tokenId);
    }

    function unlockNativeToken(bytes32 txHash, address to, uint256 amount) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(nativeTokenTxHashUnlocked[txHash] == false, "Transaction has been executed");
        nativeTokenTxHashUnlocked[txHash] = true;
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        allNativeTokenTxHash.push(txHash);
        userNativeTokenMintTxHash[to].push(txHash);
        emit UnlockNativeToken(txHash, to, amount);
    }

    function lockNativeToken() public payable {
        require(msg.value > bridgeFee, "Insufficient cross-chain assets");

        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }

        emit LockNativeToken(msg.sender, msg.value - bridgeFee);
    }

    function allERC20TokenAddressLength() public view returns(uint256) {
        return allERC20TokenAddress.length;
    }

    function allERC20TxHashLength() public view returns(uint256) {
        return allERC20TxHash.length;
    }

    function allERC721TokenAddressLength() public view returns(uint256) {
        return allERC721TokenAddress.length;
    }

    function allERC721TxHashLength() public view returns(uint256) {
        return allERC721TxHash.length;
    }

    function allNativeTokenTxHashLength() public view returns(uint256) {
        return allNativeTokenTxHash.length;
    }

    function userERC20MintTxHashLength(address user) public view returns(uint256) {
        return userERC20MintTxHash[user].length;
    }

    function userERC721MintTxHashLength(address user) public view returns(uint256) {
        return userERC721MintTxHash[user].length;
    }

    function userNativeTokenMintTxHashLength(address user) public view returns(uint256) {
        return userNativeTokenMintTxHash[user].length;
    }

    function setBridgeSettingsFee(address _feeAddress, uint256 _bridgeFee) external {
        require(msg.sender == superAdminAddress, "Illegal permissions");

        if (_feeAddress != address(0)) {
            feeAddress = _feeAddress;
        }
        if (_bridgeFee > 0) {
            bridgeFee = _bridgeFee;
        }
    }
}