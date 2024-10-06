// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TRTStrings {
    function getCharByIndex(string memory _originString, uint8 index)
        internal
        pure
        returns (string memory _charByIndex)
    {
        bytes memory charByte = new bytes(1);
        charByte[index] = bytes(_originString)[index];
        return string(charByte);
    }
}