// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library BridgeFeeRates {
    //white list
    struct stRate{
        bool isSet;
        uint256 rate;
    }

    struct White {
        mapping(address => stRate) whiteList;
    }

    //_address is msg.sender or token.
    function setWhiteList(White storage white, address _address, uint256 _rate) internal {
        require(_address != address (0), "invalid _address");
        require(_rate >= 0, "invalid _rate");

        white.whiteList[_address] = stRate(true, _rate);
    }

    function deleteWhiteList(White storage white, address _address) internal {
        require(_address != address (0), "invalid _address");
        delete white.whiteList[_address];
    }


    function getBridgeFeeRate(White storage white, address msgSender, address token) internal view returns(uint256) {
        if (white.whiteList[msgSender].isSet) {
            return white.whiteList[msgSender].rate;
        }

        if (token != address (0) && white.whiteList[token].isSet) {
            return white.whiteList[token].rate;
        }

        return 100;
    }

    function getBridgeFeeRateTimes(White storage white, address msgSender, address token, uint256 times) internal view returns(uint256) {
        return getBridgeFeeRate(white, msgSender, token) * times;
    }
}