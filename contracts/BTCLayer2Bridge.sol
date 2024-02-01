// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBTCLayer2BridgeERC20.sol";
import "./interfaces/IBTCLayer2BridgeERC721.sol";

contract BTCLayer2Bridge is OwnableUpgradeable {
    address public superAdminAddress;
    address public normalAdminAddress;
    address[] public unlockTokenAdminAddressList;
    mapping(address => bool) public unlockTokenAdminAddressSupported;

    // nativeToken
    mapping(bytes32 => bool) public nativeTokenTxHashUnlocked;
    bytes32[] public allNativeTokenTxHash;
    mapping(address => bytes32[]) public userNativeTokenMintTxHash;

    address public bridgeERC20Address;
    address public bridgeERC721Address;

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
        uint8 decimals,
        uint256 cap
    );

    event SetNormalAdminAddress(
        address account
    );

    event AddUnlockTokenAdminAddress(
        address account
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
        uint256 amount,
        string destBtcAddr
    );

    event AddERC721TokenWrapped(
        address tokenWrappedAddress,
        string name,
        string symbol,
        string baseURI
    );

    event SetBaseURI(
        address token,
        string newBaseTokenURI
    );

    event BatchMintERC721Token(
        bytes32 txHash,
        address token,
        address account,
        uint256[] inscriptionNumbers,
        string[] inscriptionIds
    );

    event BatchBurnERC721Token(
        address token,
        address account,
        string destBtcAddr,
        uint256[] inscriptionNumbers,
        string[] inscriptionIds
    );

    event UnlockNativeToken(
        bytes32 txHash,
        address account,
        uint256 amount
    );

    event LockNativeToken(
        address account,
        uint256 amount,
        string destBtcAddr
    );

    event SetBridgeSettingsFee(
        address feeAddress,
        uint256 bridgeFee
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
        address _bridgeERC20Address,
        address _bridgeERC721Address,
        address _feeAddress
    ) external onlyValidAddress(_initialOwner)
    onlyValidAddress(_superAdminAddress)
    onlyValidAddress(_bridgeERC20Address)
    onlyValidAddress(_bridgeERC721Address)
    onlyValidAddress(_feeAddress) virtual initializer {
        superAdminAddress = _superAdminAddress;
        bridgeERC20Address = _bridgeERC20Address;
        bridgeERC721Address = _bridgeERC721Address;
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
        emit SetNormalAdminAddress(_account);
    }

    function addUnlockTokenAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        require(unlockTokenAdminAddressSupported[_account] == false, "Current address has been added");
        unlockTokenAdminAddressList.push(_account);
        unlockTokenAdminAddressSupported[_account] = true;
        emit AddUnlockTokenAdminAddress(_account);
    }

    function addERC20TokenWrapped(string memory _name, string memory _symbol, uint8 _decimals, uint256 _cap) public returns(address) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        address tokenWrappedAddress = IBTCLayer2BridgeERC20(bridgeERC20Address).addERC20TokenWrapped(_name, _symbol, _decimals, _cap);
        emit AddERC20TokenWrapped(tokenWrappedAddress, _name, _symbol, _decimals, _cap);
        return tokenWrappedAddress;
    }

    function mintERC20Token(bytes32 txHash, address token, address to, uint256 amount) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        IBTCLayer2BridgeERC20(bridgeERC20Address).mintERC20Token(txHash, token, to, amount);
        emit MintERC20Token(txHash, token, to, amount);
    }

    function burnERC20Token(address token, uint256 amount, string memory destBtcAddr) public payable {
        require(msg.value == bridgeFee, "The bridgeFee is incorrect");
        IBTCLayer2BridgeERC20(bridgeERC20Address).burnERC20Token(msg.sender, token, amount);
        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit BurnERC20Token(token, msg.sender, amount, destBtcAddr);
    }

    function addERC721TokenWrapped(string memory _name, string memory _symbol, string memory _baseURI) public returns(address) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        address tokenWrappedAddress = IBTCLayer2BridgeERC721(bridgeERC721Address).addERC721TokenWrapped(_name, _symbol, _baseURI);
        emit AddERC721TokenWrapped(tokenWrappedAddress, _name, _symbol, _baseURI);
        return tokenWrappedAddress;
    }

    function setBaseURI(address token, string calldata newBaseTokenURI) public {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        IBTCLayer2BridgeERC721(bridgeERC721Address).setBaseURI(token, newBaseTokenURI);
        emit SetBaseURI(token, newBaseTokenURI);
    }

    function tokenURI(address token, uint256 inscriptionNumber) public returns (string memory) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        return IBTCLayer2BridgeERC721(bridgeERC721Address).tokenURI(token, inscriptionNumber);
    }

    function batchMintERC721Token(bytes32 txHash, address token, address to, string[] memory inscriptionIds, uint256[] memory inscriptionNumbers) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(inscriptionIds.length <= 100, "inscriptionIds's length is too many");

        IBTCLayer2BridgeERC721(bridgeERC721Address).batchMintERC721Token(txHash, token, to, inscriptionIds, inscriptionNumbers);
        emit BatchMintERC721Token(txHash, token, to, inscriptionNumbers, inscriptionIds);
    }

    function batchBurnERC721Token(address token, string memory destBtcAddr, uint256[] memory inscriptionNumbers) public payable {
        require(inscriptionNumbers.length <= 100, "inscriptionNumbers's length is too many");
        require(msg.value == bridgeFee, "The bridgeFee is incorrect");

        string[] memory inscriptionIds;
        inscriptionIds = IBTCLayer2BridgeERC721(bridgeERC721Address).batchBurnERC721Token(msg.sender, token, inscriptionNumbers);
        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit BatchBurnERC721Token(token, msg.sender, destBtcAddr, inscriptionNumbers, inscriptionIds);
    }

    function unlockNativeToken(bytes32 txHash, address to, uint256 amount) public {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(to != address(0x0), "to address is zero address");
        require(nativeTokenTxHashUnlocked[txHash] == false, "Transaction has been executed");
        nativeTokenTxHashUnlocked[txHash] = true;
        allNativeTokenTxHash.push(txHash);
        userNativeTokenMintTxHash[to].push(txHash);
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit UnlockNativeToken(txHash, to, amount);
    }

    function lockNativeToken(string memory destBtcAddr) public payable {
        require(msg.value > bridgeFee, "Insufficient cross-chain assets");

        (bool success, ) = feeAddress.call{value: bridgeFee}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }

        emit LockNativeToken(msg.sender, msg.value - bridgeFee, destBtcAddr);
    }

    function allERC20TokenAddressLength() public view returns(uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).allERC20TokenAddressLength();
    }

    function allERC20TxHashLength() public view returns(uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).allERC20TxHashLength();
    }

    function allERC721TokenAddressLength() public view returns(uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).allERC721TokenAddressLength();
    }

    function allERC721TxHashLength() public view returns(uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).allERC721TxHashLength();
    }

    function allNativeTokenTxHashLength() public view returns(uint256) {
        return allNativeTokenTxHash.length;
    }

    function userERC20MintTxHashLength(address user) public view returns(uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).userERC20MintTxHashLength(user);
    }

    function userERC721MintTxHashLength(address user) public view returns(uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).userERC721MintTxHashLength(user);
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

        emit SetBridgeSettingsFee(_feeAddress, _bridgeFee);
    }
}
