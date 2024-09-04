// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BtcAddressCheck {
    uint256 internal constant _WORD_SIZE = 32;
    bytes1 internal constant _PUBKEY_HASH_ADDR_ID_MAINNET = 0x00;
    bytes1 internal constant _SCRIPT_HASH_ADDR_ID_MAINNET = 0x05;
    bytes1 internal constant _PUBKEY_HASH_ADDR_ID_TESTNET = 0x6f;
    bytes1 internal constant _SCRIPT_HASH_ADDR_ID_TESTNET = 0xc4;
    uint256 internal constant _BTC_MAINNET_SIGN = 1;
    uint256 internal constant _BTC_TESTNET_SIGN = 2;

    bytes internal constant _BASE58_INDEX =
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ffffffffffffffffffffffffffffffffff000102030405060708ffffffffffff"
    hex"ff090a0b0c0d0e0f10ff1112131415ff161718191a1b1c1d1e1f20ffffffffff"
    hex"ff2122232425262728292a2bff2c2d2e2f30313233343536373839ffffffffff"
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    bytes internal constant _BECH32_INDEX =
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ffffffffffffffffffffffffffffffff0fff0a1115141a1e0705ffffffffffff"
    hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    hex"ff1dff180d19090817ff12161f1b13ff010003100b1c0c0e060402";

    struct Params {
        uint256 btcNetSign;
        bytes1 pubKeyHashAddrID;
        bytes1 scriptHashAddrID;
        bytes bech32HRPSegwit;
    }

    function initializeParams(string calldata btcSegwit)
    public
    pure
    returns (Params memory)
    {
        bytes memory segwitBytes = bytes(btcSegwit);
        Params memory params;

        if (segwitBytes.length != 0) {
            params.bech32HRPSegwit = segwitBytes;
        } else {
            params.bech32HRPSegwit = bytes("bc");
        }

        if (
            params.bech32HRPSegwit.length >= 2 &&
            params.bech32HRPSegwit[0] == 0x62 &&
            params.bech32HRPSegwit[1] == 0x63
        ) {
            params.btcNetSign = _BTC_MAINNET_SIGN;
            params.pubKeyHashAddrID = _PUBKEY_HASH_ADDR_ID_MAINNET;
            params.scriptHashAddrID = _SCRIPT_HASH_ADDR_ID_MAINNET;
        } else if (
            params.bech32HRPSegwit.length >= 2 &&
            params.bech32HRPSegwit[0] == 0x74 &&
            params.bech32HRPSegwit[1] == 0x62
        ) {
            params.btcNetSign = _BTC_TESTNET_SIGN;
            params.pubKeyHashAddrID = _PUBKEY_HASH_ADDR_ID_TESTNET;
            params.scriptHashAddrID = _SCRIPT_HASH_ADDR_ID_TESTNET;
        }
        return params;
    }

    // verify the bitcoin address
    function isValidBitcoinAddress(Params calldata params, string calldata addr)
    public
    pure
    returns (bool)
    {
        bytes memory addrBytes = bytes(addr);

        // the bitcoin address start as '1' or '3'
        if (addrBytes[0] == 0x31 || addrBytes[0] == 0x33) {
            return checkBase58(params, addrBytes);
        }

        // bc1 or tb1
        uint256 index;
        if (
            (params.btcNetSign == 1 &&
            addrBytes[0] == 0x62 &&
            addrBytes[1] == 0x63 &&
                addrBytes[2] == 0x31) ||
            (params.btcNetSign == 2 &&
            addrBytes[0] == 0x74 &&
            addrBytes[1] == 0x62 &&
                addrBytes[2] == 0x31)
        ) {
            index = 2;
            if (
                addrBytes.length > 90 ||
                addrBytes.length < 8 ||
                index + 7 > addrBytes.length
            ) {
                //"the type of P2TR or P2WPKH btc address need length <= 90 or >=8"
                return false;
            }
            return checkBech32(addrBytes, index);
        }

        index = findLastIndexByte(addrBytes, "1");
        if ((index > 1) && isBech32(params, slice(addrBytes, 0, index))) {
            if (
                addrBytes.length > 90 ||
                addrBytes.length < 8 ||
                index + 7 > addrBytes.length
            ) {
                return false;
            }
            return checkBech32(addrBytes, index);
        }
        return checkBase58(params, addrBytes);
    }

    function checkBase58(Params calldata params, bytes memory inputs)
    public
    pure
    returns (bool)
    {
        bytes memory decoded = base58Decode(inputs);
        uint256 length = decoded.length;
        if (length < 5) {
            return false;
        }
        bool isP2PKH = decoded[0] == params.pubKeyHashAddrID;
        bool isP2SH = decoded[0] == params.scriptHashAddrID;
        if ((params.scriptHashAddrID != 0x00) && (isP2PKH == isP2SH)) {
            return false;
        }
        bytes32 h2 = sha256(toBytes(sha256(slice(decoded, 0, length - 4))));
        return
            decoded[length - 4] == h2[0] &&
            decoded[length - 3] == h2[1] &&
            decoded[length - 2] == h2[2] &&
            decoded[length - 1] == h2[3];
    }

    function base58Decode(bytes memory data_)
    public
    pure
    returns (bytes memory)
    {
        unchecked {
            uint256 zero = 49;
            uint256 b58sz = data_.length;
            uint256 zcount = 0;
            for (uint256 i = 0; i < b58sz && uint8(data_[i]) == zero; i++) {
                zcount++;
            }
            uint256 t;
            uint256 c;
        //bool f;
            bytes memory binu = new bytes(2 * (((b58sz * 8351) / 6115) + 1));
            uint32[] memory outi = new uint32[]((b58sz + 3) / 4);
            for (uint256 i = 0; i < data_.length; i++) {
                bytes1 r = data_[i];
                c = uint8(_BASE58_INDEX[uint8(r)]);
                if (c == 0xff) {
                    revert("invalid base58 digit");
                }
                for (int256 k = int256(outi.length) - 1; k >= 0; k--) {
                    t = uint64(outi[uint256(k)]) * 58 + c;
                    c = t >> 32;
                    outi[uint256(k)] = uint32(t & 0xffffffff);
                }
            }
            uint64 mask = uint64(b58sz % 4) * 8;
            if (mask == 0) {
                mask = 32;
            }
            mask -= 8;
            uint256 outLen = 0;
            for (uint256 j = 0; j < outi.length; j++) {
                while (mask < 32) {
                    binu[outLen] = bytes1(uint8(outi[j] >> mask));
                    outLen++;
                    if (mask < 8) {
                        break;
                    }
                    mask -= 8;
                }
                mask = 24;
            }
            for (uint256 msb = zcount; msb < binu.length; msb++) {
                if (binu[msb] > 0) {
                    return slice(binu, msb - zcount, outLen);
                }
            }
            return slice(binu, 0, outLen);
        }
    }

    function isBech32(Params calldata params, bytes memory input)
    public
    pure
    returns (bool)
    {
        if (input.length != params.bech32HRPSegwit.length) {
            return false;
        }
        for (uint256 i = 0; i < input.length; i++) {
            bytes1 r = input[i];
            if (uint8(r) >= 65 && uint8(r) <= 90) {
                if ((bytes1(uint8(r) + 32) != params.bech32HRPSegwit[i])) {
                    // conver to lower character
                    return false;
                }
            } else {
                if (r != params.bech32HRPSegwit[i]) {
                    return false;
                }
            }
        }
        return true;
    }

    function checkBech32(bytes memory input, uint256 index)
    public
    pure
    returns (bool)
    {
        uint256 length = input.length;
        bool hasLower;
        bool hasUpper;
        for (uint256 i = 0; i < length; i++) {
            bytes1 r = input[i];
            if (uint8(r) < 33 || uint8(r) > 126) {
                revert("only characters between 33 and 126 are allowed");
            }

            if (!hasLower && uint8(r) >= 97 && uint8(r) <= 122) {
                hasLower = true;
            }

            if (uint8(r) >= 65 && uint8(r) <= 90) {
                hasUpper = true;
                input[i] = bytes1(uint8(r) + 32); // conver to lower character
            }

            if (hasLower && hasUpper) {
                revert("string not all lowercase or all uppercase");
            }
        }

        // get human-readable and data part
        bytes memory hrp = slice(input, 0, index);
        bytes memory data = slice(input, index + 1, length);
        bytes memory decoded = bechDecode(data);
        uint256 polymod = bech32Polymod(
            hrp,
            slice(decoded, 0, decoded.length - 6),
            slice(decoded, decoded.length - 6, decoded.length)
        );
        if (uint8(decoded[0]) == 0 && polymod == 1) {
            // bech32
            return true;
        }

        if (uint8(decoded[0]) == 1 && polymod == 0x2bc830a3) {
            // bech32m
            return true;
        }
        return false;
    }

    /// @dev The original function used the neg (-) operator. Ref: https://github.com/bitcoinjs/bech32/blob/master/src/index.ts#L10-L20
    /// Since the neg operator is not available for uint type, the logic is modified as follow
    function polymodStep(uint256 pre) public pure returns (uint256) {
        uint256 b = pre >> 25;
        return (((pre & 0x1ffffff) << 5) ^
        (((b >> 0) & 1) == 0 ? 0 : 0x3b6a57b2) ^
        (((b >> 1) & 1) == 0 ? 0 : 0x26508e6d) ^
        (((b >> 2) & 1) == 0 ? 0 : 0x1ea119fa) ^
        (((b >> 3) & 1) == 0 ? 0 : 0x3d4233dd) ^
            (((b >> 4) & 1) == 0 ? 0 : 0x2a1462b3));
    }

    function bechDecode(bytes memory data) public pure returns (bytes memory) {
        bytes memory reBytes = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            reBytes[i] = bytes1(_BECH32_INDEX[uint8(data[i])]);
            if (reBytes[i] == 0xff) {
                revert("invalid bench digit");
            }
        }
        return reBytes;
    }

    function bech32Polymod(
        bytes memory hrp,
        bytes memory values,
        bytes memory checksum
    ) public pure returns (uint256) {
        uint256 chk = 1;
        // Account for the high bits of the HRP in the checksum.
        for (uint256 i = 0; i < hrp.length; i++) {
            chk = polymodStep(chk) ^ (uint256(uint8(hrp[i])) >> 5);
        }

        // Account for the separator (0) between high and low bits of the HRP.
        // x^0 == x, so we eliminate the redundant xor used in the other rounds.
        chk = polymodStep(chk);

        // Account for the low bits of the HRP.
        for (uint256 i = 0; i < hrp.length; i++) {
            chk = polymodStep(chk) ^ (uint256(uint8(hrp[i])) & 31);
        }

        // Account for the values.
        for (uint256 i = 0; i < values.length; i++) {
            chk = polymodStep(chk) ^ uint256(uint8(values[i]));
        }

        // Checksum is provided during decoding, so use it.
        for (uint256 i = 0; i < checksum.length; i++) {
            chk = polymodStep(chk) ^ uint256(uint8(checksum[i]));
        }

        return chk;
    }

    function toBytes(bytes32 _data) public pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }

    // /**
    //  * @notice slice is used to slice the given byte, returns the bytes in the range of [start_, end_)
    //  * @param data_ raw data, passed in as bytes.
    //  * @param start_ start index.
    //  * @param end_ end index.
    //  * @return slice data
    //  */
    // function slice(
    //     bytes memory data_,
    //     uint256 start_,
    //     uint256 end_
    // ) public pure returns (bytes memory) {
    //     unchecked {
    //         uint length = end_ - start_;
    //         bytes memory ret = new bytes(length);
    //         for (uint256 i = 0; i < length; i++) {
    //             ret[i] = data_[i + start_];
    //         }
    //         return ret;
    //     }
    // }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 end
    ) public pure returns (bytes memory) {
        uint256 len = end - start;
        bytes memory result = new bytes(len);

        uint256 src;
        uint256 dest;
        assembly {
            src := add(data, add(start, 32))
            dest := add(result, 32)
        }
        for (; len >= _WORD_SIZE; len -= _WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += _WORD_SIZE;
            src += _WORD_SIZE;
        }

        if (len == 0) return result;

        // Copy remaining bytes
        uint256 mask = 256**(_WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return result;
    }

    function findLastIndexByte(bytes memory data, bytes1 toFind)
    public
    pure
    returns (uint256)
    {
        for (uint256 i = data.length - 1; i > 0; i--) {
            if (data[i] == toFind) {
                return i;
            }
        }
        return 0;
    }
}
