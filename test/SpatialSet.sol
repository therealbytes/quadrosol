// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IObj.sol";

import {Set, SpatialSet, SpatialSetLib} from "../src/SpatialSet.sol";

contract SpatialSetObj is IObj {
    using SpatialSetLib for SpatialSet;

    SpatialSet internal set;

    constructor(Rect memory rect) {
        set.rect = rect;
        set.set = new Set();
    }

    function size() external view returns (uint256) {
        return set.size();
    }

    function insert(Point memory point) external returns (bool) {
        return set.insert(point);
    }

    function remove(Point memory point) external returns (bool) {
        return set.remove(point);
    }

    function contains(Point memory point) external view returns (bool) {
        return set.contains(point);
    }

    function searchRect(Rect memory rect)
        external
        view
        returns (Point[] memory)
    {
        return set.searchRect(rect);
    }
}
