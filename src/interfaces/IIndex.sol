// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point, Rect} from "../geo/Index.sol";

interface IIndexRead {
    // Returns the number of points in the index.
    function size() external view returns (uint256);

    // Returns true if the index has the point.
    function has(Point memory point) external view returns (bool);

    // Returns all points in the index within the given rectangle.
    function searchRect(
        Rect memory rect
    ) external view returns (Point[] memory);

    // Returns the point in the index nearest to the given point or false if the index is empty.
    function nearest(
        Point memory point
    ) external view returns (Point memory, bool);
}

interface IIndexWrite {
    // Adds a point into the index. Returns false if the point was already in the index
    // and true otherwise.
    function add(Point memory point) external returns (bool);

    // Removes a point from the index. Returns false if the point was not in the index
    // and true otherwise.
    function remove(Point memory point) external returns (bool);
}

interface IIndex is IIndexRead, IIndexWrite {}
