// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {Point, Rect} from "../src/Geo.sol";
import {IIndex} from "../src/interfaces/IIndex.sol";
import {QuadTreeObj} from "../src/QuadTree.sol";
import {SpatialSetObj} from "../src/SpatialSet.sol";

abstract contract ObjTest is Test {
    IIndex internal obj;
    Rect internal rect;

    function setUp() public virtual {
        rect = Rect(Point(-10, -10), Point(10, 10));
    }

    function testInsert() public {
        Point memory point = Point(0, 0);
        assertTrue(obj.insert(point));
        assertFalse(obj.insert(point));
        assertTrue(obj.size() == 1);
    }

    function testRemove() public {
        Point memory point = Point(0, 0);
        assertTrue(obj.insert(point));
        assertTrue(obj.remove(point));
        assertFalse(obj.remove(point));
        assertTrue(obj.size() == 0);
    }

    function testContains() public {
        Point memory point = Point(0, 0);
        assertFalse(obj.contains(point));
        assertTrue(obj.insert(point));
        assertTrue(obj.contains(point));
    }

    function testSearchRect() public {
        Point memory pIn0 = Point(0, 0);
        Point memory pIn1 = Point(1, 1);
        Point memory pOut0 = Point(5, 5);
        Point memory pOut1 = Point(-5, -5);
        assertTrue(obj.insert(pIn0));
        assertTrue(obj.insert(pIn1));
        assertTrue(obj.insert(pOut0));
        assertTrue(obj.insert(pOut1));
        Point[] memory points = obj.searchRect(
            Rect(Point(-1, -1), Point(2, 2))
        );
        assertEq(points.length, 2);
        for (uint256 i = 0; i < points.length; i++) {
            assertTrue(pointEq(points[i], pIn0) || pointEq(points[i], pIn1));
        }
    }

    function testNearest() public {
        Point memory p0 = Point(0, 0);
        Point memory p1 = Point(1, 1);
        Point memory p2 = Point(5, 5);
        Point memory p3 = Point(-5, -5);
        assertTrue(obj.insert(p0));
        assertTrue(obj.insert(p1));
        assertTrue(obj.insert(p2));
        assertTrue(obj.insert(p3));
        (Point memory point, bool ok) = obj.nearest(Point(6, 6));
        assertTrue(ok);
        assertTrue(pointEq(point, p2));
    }

    function pointEq(Point memory a, Point memory b)
        internal
        pure
        returns (bool)
    {
        return a.x == b.x && a.y == b.y;
    }
}

contract QuadTreeTest is ObjTest {
    function setUp() public override {
        super.setUp();
        obj = new QuadTreeObj(rect);
    }
}

contract SpatialSetTest is ObjTest {
    function setUp() public override {
        super.setUp();
        obj = new SpatialSetObj(rect);
    }
}
