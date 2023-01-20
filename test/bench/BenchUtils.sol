// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {console} from "forge-std/Console.sol";
import {Point} from "../../src/Geo.sol";

abstract contract BenchUtils {
    bytes32 internal rnd;

    function randomUint(uint256 max) internal returns (uint256) {
        rnd = keccak256(abi.encodePacked(rnd));
        return uint256(rnd) % max;
    }

    function insertMany(uint256 i) internal {
        insertMany(0, int256(i));
    }

    function insertMany(int256 a, int256 b) internal {
        for (int256 i = a; i < b; i++) {
            insert(Point(int32(int256(i)), int32(int256(i))));
        }
    }

    function testAction() public {
        precheck();
        uint256 gasLeft = gasleft();
        action();
        logResult(gasLeft - gasleft());
    }

    function logResult(uint256 gas) internal virtual {
        console.log("Benchmark-%d: %d", n(), gas);
    }

    function precheck() internal virtual;

    function action() internal virtual;

    function n() internal view virtual returns (uint256);

    function insert(Point memory point) internal virtual;
}
