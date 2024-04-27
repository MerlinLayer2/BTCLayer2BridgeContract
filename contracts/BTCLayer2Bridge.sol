// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBTCLayer2BridgeERC20.sol";
import "./interfaces/IBTCLayer2BridgeERC721.sol";
import "./BridgeFeeRates.sol";

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

    string public constant version = "1.3.0";

    uint256 public constant MaxBridgeFee = 50000000000000000; //max 0.05

    address public pauseAdmin;
    bool public paused;

    using BridgeFeeRates for BridgeFeeRates.White;
    BridgeFeeRates.White private white;

    event SetWhiteList(
        address adminSetter,
        address addressKey,
        uint256 rate
    );

    event DeleteWhiteList(
        address adminSetter,
        address addressKey
    );


    event SuperAdminAddressChanged(
        address oldAddress,
        address newAddress
    );

    event PauseAdminChanged(
        address adminSetter,
        address oldAddress,
        address newAddress
    );

    event PauseEvent(
        address pauseAdmin,
        bool paused
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

    event DelUnlockTokenAdminAddress(
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
        string destBtcAddr,
        uint256 bridgeFee
    );

    event SetBlackListERC20Token(
        address adminSetter,
        address token,
        address account,
        bool state
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
        uint256[] tokenIds,
        string[] inscriptionIds
    );

    event BatchBurnERC721Token(
        address token,
        address account,
        string destBtcAddr,
        uint256[] tokenIds,
        string[] inscriptionIds,
        uint256 bridgeFee
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

    event LockNativeTokenWithBridgeFee(
        address account,
        uint256 amount,
        string destBtcAddr,
        uint256 bridgeFee
    );

    event SetBridgeSettingsFee(
        address feeAddress,
        uint256 bridgeFee,
        address feeAddressOld,
        uint256 bridgeFeeOld
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
        require(!unlockTokenAdminAddressSupported[_account], "Current address has been added");
        unlockTokenAdminAddressList.push(_account);
        unlockTokenAdminAddressSupported[_account] = true;
        emit AddUnlockTokenAdminAddress(_account);
    }

    function delUnlockTokenAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        require(unlockTokenAdminAddressSupported[_account] == true, "Current address is not exist");
        unlockTokenAdminAddressSupported[_account] = false;

        uint16 i = 0;
        for (i = 0; i < unlockTokenAdminAddressList.length; i++) {
            if (unlockTokenAdminAddressList[i] == _account) {
                break;
            }
        }
        require(i < unlockTokenAdminAddressList.length, "Current address is out of unlockTokenAdminAddressList");
        unlockTokenAdminAddressList[i] = unlockTokenAdminAddressList[unlockTokenAdminAddressList.length - 1];
        unlockTokenAdminAddressList.pop();

        emit DelUnlockTokenAdminAddress(_account);
    }

    function addERC20TokenWrapped(string memory _name, string memory _symbol, uint8 _decimals, uint256 _cap) public returns (address) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        address tokenWrappedAddress = IBTCLayer2BridgeERC20(bridgeERC20Address).addERC20TokenWrapped(_name, _symbol, _decimals, _cap);
        emit AddERC20TokenWrapped(tokenWrappedAddress, _name, _symbol, _decimals, _cap);
        return tokenWrappedAddress;
    }

    function mintERC20Token(bytes32 txHash, address token, address to, uint256 amount) public whenNotPaused {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        IBTCLayer2BridgeERC20(bridgeERC20Address).mintERC20Token(txHash, token, to, amount);
        emit MintERC20Token(txHash, token, to, amount);
    }

    function burnERC20Token(address token, uint256 amount, string memory destBtcAddr) public payable whenNotPaused {
        uint256 _bridgeFee = getBridgeFee(msg.sender, token);
        require(msg.value == _bridgeFee, "invalid bridgeFee");

        //todo 1.是否所有msg.value 都设置为 bridgeFee 2.前端需要调用合约获取 bridgeFee
        if (_bridgeFee > 0) {
            (bool success,) = feeAddress.call{value:  _bridgeFee}(new bytes(0));
            if (!success) {
                revert EtherTransferFailed();
            }
        }

        IBTCLayer2BridgeERC20(bridgeERC20Address).burnERC20Token(msg.sender, token, amount);
        emit BurnERC20Token(token, msg.sender, amount, destBtcAddr, _bridgeFee);
    }

    function setBlackListERC20Token(address token, address account, bool state) external {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        IBTCLayer2BridgeERC20(bridgeERC20Address).setBlackListERC20Token(token, account, state);
        emit SetBlackListERC20Token(msg.sender, token, account, state);
    }

    function addERC721TokenWrapped(string memory _name, string memory _symbol, string memory _baseURI) public returns (address) {
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

    function tokenURI(address token, uint256 tokenId) public returns (string memory) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).tokenURI(token, tokenId);
    }

    function batchMintERC721Token(bytes32 txHash, address token, address to, string[] memory inscriptionIds, uint256[] memory tokenIds) public whenNotPaused {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");

        IBTCLayer2BridgeERC721(bridgeERC721Address).batchMintERC721Token(txHash, token, to, inscriptionIds, tokenIds);
        emit BatchMintERC721Token(txHash, token, to, tokenIds, inscriptionIds);
    }

    function batchBurnERC721Token(address token, string memory destBtcAddr, uint256[] memory tokenIds) public payable whenNotPaused {
        uint256 _bridgeFee = getBridgeFeeTimes(msg.sender, token, tokenIds.length);
        require(msg.value == _bridgeFee, "invalid bridgeFee");

        //todo 1.是否所有msg.value 都设置为 bridgeFee 2.前端需要调用合约获取 bridgeFee
        if (_bridgeFee > 0) {
            (bool success,) = feeAddress.call{value: _bridgeFee}(new bytes(0));
            if (!success) {
                revert EtherTransferFailed();
            }
        }

        string[] memory inscriptionIds;
        inscriptionIds = IBTCLayer2BridgeERC721(bridgeERC721Address).batchBurnERC721Token(msg.sender, token, tokenIds);
        emit BatchBurnERC721Token(token, msg.sender, destBtcAddr, tokenIds, inscriptionIds, _bridgeFee);
    }

    function unlockNativeToken(bytes32 txHash, address to, uint256 amount) public whenNotPaused {
        require(unlockTokenAdminAddressSupported[msg.sender], "Illegal permissions");
        require(to != address(0x0), "to address is zero address");
        require(!nativeTokenTxHashUnlocked[txHash], "Transaction has been executed");
        nativeTokenTxHashUnlocked[txHash] = true;
        allNativeTokenTxHash.push(txHash);
        userNativeTokenMintTxHash[to].push(txHash);
        (bool success,) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert EtherTransferFailed();
        }
        emit UnlockNativeToken(txHash, to, amount);
    }

    function lockNativeToken(string memory destBtcAddr) public payable whenNotPaused {
        uint256 _bridgeFee = getBridgeFee(msg.sender, address (0));
        require(msg.value > _bridgeFee, "Insufficient cross-chain assets");

        if (_bridgeFee > 0) {
            (bool success,) = feeAddress.call{value: _bridgeFee}(new bytes(0));
            if (!success) {
                revert EtherTransferFailed();
            }
        }

        emit LockNativeTokenWithBridgeFee(msg.sender, msg.value - _bridgeFee, destBtcAddr, _bridgeFee);
    }

    function allERC20TokenAddressLength() public view returns (uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).allERC20TokenAddressLength();
    }

    function allERC20TxHashLength() public view returns (uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).allERC20TxHashLength();
    }

    function allERC721TokenAddressLength() public view returns (uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).allERC721TokenAddressLength();
    }

    function allERC721TxHashLength() public view returns (uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).allERC721TxHashLength();
    }

    function allNativeTokenTxHashLength() public view returns (uint256) {
        return allNativeTokenTxHash.length;
    }

    function userERC20MintTxHashLength(address user) public view returns (uint256) {
        return IBTCLayer2BridgeERC20(bridgeERC20Address).userERC20MintTxHashLength(user);
    }

    function userERC721MintTxHashLength(address user) public view returns (uint256) {
        return IBTCLayer2BridgeERC721(bridgeERC721Address).userERC721MintTxHashLength(user);
    }

    function userNativeTokenMintTxHashLength(address user) public view returns (uint256) {
        return userNativeTokenMintTxHash[user].length;
    }

    function setBridgeSettingsFee(address _feeAddress, uint256 _bridgeFee) external {
        require(msg.sender == superAdminAddress, "Illegal permissions");
        require(_bridgeFee <= MaxBridgeFee, "bridgeFee is too high"); //max 0.05

        address feeAddressOld = feeAddress;
        uint256 bridgeFeeOld = bridgeFee;

        if (_feeAddress != address(0)) {
            feeAddress = _feeAddress;
        }
        if (_bridgeFee > 0) {
            bridgeFee = _bridgeFee;
        }

        emit SetBridgeSettingsFee(_feeAddress, _bridgeFee, feeAddressOld, bridgeFeeOld);
    }

    function setPauseAdminAddress(address _account) public onlyValidAddress(_account) {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal permissions");
        address oldPauseAdmin = pauseAdmin;
        pauseAdmin = _account;
        emit PauseAdminChanged(msg.sender, oldPauseAdmin, pauseAdmin);
    }

    modifier whenNotPaused() {
        require(!paused, "pause is on");
        _;
    }

    function pause() public whenNotPaused {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress || msg.sender == pauseAdmin, "Illegal pause permissions");
        paused = true;
        emit PauseEvent(msg.sender, paused);
    }

    function unpause() public {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal pause permissions");
        paused = false;
        emit PauseEvent(msg.sender, paused);
    }

    //_address is msg.sender or token.
    function setWhiteList(address _address, uint256 _rate) external {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal pause permissions");
        white.setWhiteList(_address, _rate);
        emit SetWhiteList(msg.sender, _address, _rate);
    }

    function deleteWhiteList(address _address) external {
        require(msg.sender == superAdminAddress || msg.sender == normalAdminAddress, "Illegal pause permissions");
        white.deleteWhiteList(_address);
        emit DeleteWhiteList(msg.sender, _address);
    }

    function getBridgeFee(address msgSender, address token) public view returns(uint256) {
        return bridgeFee * white.getBridgeFeeRate(msgSender, token) / 100;
    }

    function getBridgeFeeTimes(address msgSender, address token, uint256 times) public view returns(uint256) {
        return bridgeFee * white.getBridgeFeeRateTimes(msgSender, token, times) / 100;
    }
}
