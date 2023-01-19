// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {Point, Rect, Set, SpatialSet, SpatialSetLib} from "../src/SpatialSet.sol";

contract SpatialSetTest is Test {
    using SpatialSetLib for SpatialSet;

    SpatialSet set;

    function setUp() public {
        set.set = new Set();
        set.rect = Rect(Point(-10, -10), Point(10, 10));
    }

    function testInsert() public {
        Point memory point = Point(0, 0);
        assertTrue(set.insert(point));
        assertFalse(set.insert(point));
    }

    function testRemove() public {
        Point memory point = Point(0, 0);
        assertTrue(set.insert(point));
        assertTrue(set.remove(point));
        assertFalse(set.remove(point));
    }

    function testContains() public {
        Point memory point = Point(0, 0);
        assertFalse(set.contains(point));
        assertTrue(set.insert(point));
        assertTrue(set.contains(point));
    }

    function testSearchRect() public {
        Point memory pIn0 = Point(0, 0);
        Point memory pIn1 = Point(1, 1);
        Point memory pOut0 = Point(5, 5);
        Point memory pOut1 = Point(-5, -5);
        assertTrue(set.insert(pIn0));
        assertTrue(set.insert(pIn1));
        assertTrue(set.insert(pOut0));
        assertTrue(set.insert(pOut1));
        Point[] memory points = set.searchRect(
            Rect(Point(-1, -1), Point(2, 2))
        );
        assertEq(points.length, 2);
        for (uint256 i = 0; i < points.length; i++) {
            assertTrue(pointEq(points[i], pIn0) || pointEq(points[i], pIn1));
        }
    }

    function pointEq(Point memory a, Point memory b) internal returns (bool) {
        return a.x == b.x && a.y == b.y;
    }
}
