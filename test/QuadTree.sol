// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/QuadTree.sol";

contract QuadTreeTest is Test {
    using QuadTreeLib for QuadTree;

    QuadTree tree;

    function setUp() public {
        tree.rect = Rect(Point(-10, -10), Point(10, 10));
    }

    function testInsert() public {
        Point memory point = Point(0, 0);
        assertTrue(tree.insert(point));
        assertFalse(tree.insert(point));
    }

    function testRemove() public {
        Point memory point = Point(0, 0);
        assertTrue(tree.insert(point));
        assertTrue(tree.remove(point));
        assertFalse(tree.remove(point));
    }

    function testContains() public {
        Point memory point = Point(0, 0);
        assertFalse(tree.contains(point));
        assertTrue(tree.insert(point));
        assertTrue(tree.contains(point));
    }

    function testSearchRect() public {
        Point memory pIn0 = Point(0, 0);
        Point memory pIn1 = Point(1, 1);
        Point memory pOut0 = Point(5, 5);
        Point memory pOut1 = Point(-5, -5);
        assertTrue(tree.insert(pIn0));
        assertTrue(tree.insert(pIn1));
        assertTrue(tree.insert(pOut0));
        assertTrue(tree.insert(pOut1));
        Point[] memory points = tree.searchRect(
            Rect(Point(-1, -1), Point(2, 2))
        );
        assertEq(points.length, 2);
        // Note: this make assumptions about the order of the points
        assertEq(points[0], pIn0);
        assertEq(points[1], pIn1);
    }

    function assertEq(Point memory a, Point memory b) internal {
        assertEq(a.x, b.x);
        assertEq(a.y, b.y);
    }
}
