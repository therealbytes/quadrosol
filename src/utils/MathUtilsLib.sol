// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MathUtilsLib {
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) public pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) public pure returns (int256) {
        return a < b ? a : b;
    }

    function maxInt32(int32 a, int32 b) public pure returns (int32) {
        return a > b ? a : b;
    }

    function minInt32(int32 a, int32 b) public pure returns (int32) {
        return a < b ? a : b;
    }
}
