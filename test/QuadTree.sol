// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Test.sol";

import {Point, Rect, QuadTree, QuadTreeLib} from "../src/QuadTree.sol";

contract QuadTreeTest is ObjTest {
    using QuadTreeLib for QuadTree;

    QuadTree internal tree;

    function setRect(Rect memory rect) internal override {
        tree.rect = rect;
    }

    function insert(Point memory point) internal override returns (bool) {
        return tree.insert(point);
    }

    function remove(Point memory point) internal override returns (bool) {
        return tree.remove(point);
    }

    function contains(Point memory point) internal override returns (bool) {
        return tree.contains(point);
    }

    function searchRect(Rect memory rect)
        internal
        override
        returns (Point[] memory)
    {
        return tree.searchRect(rect);
    }
}
