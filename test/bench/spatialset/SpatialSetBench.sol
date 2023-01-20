// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../../src/SpatialSet.sol";

import { Bench } from "../Bench.sol";

abstract contract SpatialSetBench is Bench, Test {
    using SpatialSetLib for SpatialSet;

    SpatialSet internal set;

    function setUp() public virtual {
        set.set = new Set();
        set.rect = Rect(Point(-10000, -10000), Point(10000, 10000));
        insertMany(n());
    }

    function insert(Point memory point) internal override {
        set.insert(point);
    }

    function precheck() internal virtual override {
        assertEq(set.size(), n());
    }
}
