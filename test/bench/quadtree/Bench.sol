// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../BenchUtils.sol";
import "../../../src/QuadTree.sol";

abstract contract Bench is BenchUtils, Test {
    using QuadTreeLib for QuadTree;

    QuadTree internal tree;

    function setUp() public virtual {
        tree.rect = Rect(Point(-10000, -10000), Point(10000, 10000));
        insertMany(n());
    }

    function insert(Point memory point) internal override {
        tree.insert(point);
    }

    function testAction() public {
        precheck();
        uint256 gasLeft = gasleft();
        action();
        logResult(gasLeft - gasleft());
    }

    function precheck() internal virtual {
        assertEq(tree.size(), n());
    }

    function action() internal virtual;

    function n() internal view virtual returns (uint256) {
        return 0;
    }

    function logResult(uint256 gas) internal virtual {
        console.log("Benchmark-%d: %d", n(), gas);
    }
}
