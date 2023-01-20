// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point} from "../../src/Geo.sol";

abstract contract BenchUtils {
    bytes32 internal rnd;

    function randomUint(uint256 max) internal returns (uint256) {
        rnd = keccak256(abi.encodePacked(rnd));
        return uint256(rnd) % max;
    }

    function insertMany(uint256 n) internal {
        insertMany(0, int256(n));
    }

    function insertMany(int256 a, int256 b) internal {
        for (int256 i = a; i < b; i++) {
            insert(Point(int32(int256(i)), int32(int256(i))));
        }
    }

    function insert(Point memory point) internal virtual;
}
