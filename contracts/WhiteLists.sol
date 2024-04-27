// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Whites {
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


    function getBridgeFee(White storage white, address msgSender, address token, uint256 bridgeFee) internal view   returns(uint256) {
        if (white.whiteList[msgSender].isSet) {
            return bridgeFee * white.whiteList[msgSender].rate / 100;
        }

        if (token != address (0) && white.whiteList[token].isSet) {
            return bridgeFee * white.whiteList[token].rate / 100;
        }

        return bridgeFee;
    }

    function getBridgeFeeTimes(White storage white, address msgSender, address token, uint256 times, uint256 bridgeFee) internal view  returns(uint256) {
        return getBridgeFee(white, msgSender, token, bridgeFee) * times;
    }
}