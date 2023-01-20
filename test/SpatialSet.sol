// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Test.sol";

import {Point, Rect, Set, SpatialSet, SpatialSetLib} from "../src/SpatialSet.sol";

contract SpatialSetTest is ObjTest {
    using SpatialSetLib for SpatialSet;

    SpatialSet internal set;

    function setUp() public override {
        super.setUp();
        set.set = new Set();
    }

    function setRect(Rect memory rect) internal override {
        set.rect = rect;
    }

    function insert(Point memory point) internal override returns (bool) {
        return set.insert(point);
    }

    function remove(Point memory point) internal override returns (bool) {
        return set.remove(point);
    }

    function contains(Point memory point) internal override returns (bool) {
        return set.contains(point);
    }

    function searchRect(Rect memory rect)
        internal
        override
        returns (Point[] memory)
    {
        return set.searchRect(rect);
    }
}
