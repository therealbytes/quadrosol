// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../../src/SpatialSet.sol";

contract Bench is Test {
    using SpatialSetLib for SpatialSet;

    SpatialSet set;

    function setUp() public virtual {
        set.set = new Set();
        set.rect = Rect(Point(-10000, -10000), Point(10000, 10000));
        insertMany(n());
    }

    function testAction() public {
        precheck();
        uint256 gasLeft = gasleft();
        action();
        logResult(gasLeft - gasleft());
    }

    function insertMany(uint256 n) internal {
        for (uint256 i = 0; i < n; i++) {
            set.insert(Point(int32(int256(i)), int32(int256(i))));
        }
    }

    function precheck() internal virtual {
        assertEq(set.size(), n());
    }

    function action() internal virtual {
        set.insert(Point(-1, -1));
    }

    function n() internal view virtual returns (uint256) {
        return 0;
    }

    function logResult(uint256 gas) internal virtual {
        console.log("Benchmark-%d: %d", n(), gas);
    }
}
