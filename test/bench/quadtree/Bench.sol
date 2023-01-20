// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../../src/QuadTree.sol";

import { BenchUtils } from "../BenchUtils.sol";

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

    function precheck() internal virtual override {
        assertEq(tree.size(), n());
    }
}
