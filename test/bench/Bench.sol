// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../src/QuadTree.sol";

contract Bench is Test {
    using QuadTreeLib for QuadTree;

    QuadTree tree;

    function setUp() public virtual {
        tree.rect = Rect(Point(-10000, -10000), Point(10000, 10000));
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
            tree.insert(Point(int32(int256(i)), int32(int256(i))));
        }
    }

    function precheck() internal virtual {
        assertEq(tree.size, n());
    }

    function action() internal virtual {
        tree.insert(Point(-1, -1));
    }

    function n() internal view virtual returns (uint256) {
        return 0;
    }

    function logResult(uint256 gas) internal virtual {
        console.log("Benchmark-%d: %d", n(), gas);
    }
}
