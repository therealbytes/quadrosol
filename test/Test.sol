// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {Point, Rect} from "../src/Geo.sol";

abstract contract ObjTest is Test {
    function setRect(Rect memory rect) internal virtual;

    function insert(Point memory point) internal virtual returns (bool);

    function remove(Point memory point) internal virtual returns (bool);

    function contains(Point memory point) internal virtual returns (bool);

    function searchRect(Rect memory rect)
        internal
        virtual
        returns (Point[] memory);

    function setUp() public virtual {
        setRect(Rect(Point(-10, -10), Point(10, 10)));
    }

    function testInsert() public {
        Point memory point = Point(0, 0);
        assertTrue(insert(point));
        assertFalse(insert(point));
    }

    function testRemove() public {
        Point memory point = Point(0, 0);
        assertTrue(insert(point));
        assertTrue(remove(point));
        assertFalse(remove(point));
    }

    function testContains() public {
        Point memory point = Point(0, 0);
        assertFalse(contains(point));
        assertTrue(insert(point));
        assertTrue(contains(point));
    }

    function testSearchRect() public {
        Point memory pIn0 = Point(0, 0);
        Point memory pIn1 = Point(1, 1);
        Point memory pOut0 = Point(5, 5);
        Point memory pOut1 = Point(-5, -5);
        assertTrue(insert(pIn0));
        assertTrue(insert(pIn1));
        assertTrue(insert(pOut0));
        assertTrue(insert(pOut1));
        Point[] memory points = searchRect(Rect(Point(-1, -1), Point(2, 2)));
        assertEq(points.length, 2);
        for (uint256 i = 0; i < points.length; i++) {
            assertTrue(pointEq(points[i], pIn0) || pointEq(points[i], pIn1));
        }
    }

    function pointEq(Point memory a, Point memory b) internal returns (bool) {
        return a.x == b.x && a.y == b.y;
    }
}
