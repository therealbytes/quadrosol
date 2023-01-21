// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IObj.sol";

import {QuadTree, QuadTreeLib} from "../src/QuadTree.sol";

contract QuadTreeObj is IObj {
    using QuadTreeLib for QuadTree;

    QuadTree internal tree;

    constructor(Rect memory rect) {
        tree.rect = rect;
    }

    function size() external view returns (uint256) {
        return tree.size();
    }

    function insert(Point memory point) external returns (bool) {
        return tree.insert(point);
    }

    function remove(Point memory point) external returns (bool) {
        return tree.remove(point);
    }

    function contains(Point memory point) external view returns (bool) {
        return tree.contains(point);
    }

    function searchRect(Rect memory rect)
        external
        view
        returns (Point[] memory)
    {
        return tree.searchRect(rect);
    }

    function nearest(Point memory point) external view returns (Point memory, bool) {
        return tree.nearest(point);
    }
}
