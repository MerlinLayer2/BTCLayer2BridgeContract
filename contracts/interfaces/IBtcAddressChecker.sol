// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

interface IBtcAddressChecker {
    function isValidBitcoinAddress(string memory addr) external view returns ( bool );
}
