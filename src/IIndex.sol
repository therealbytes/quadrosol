// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point, Rect} from "./Geo.sol";

interface IIndex {
    // Returns the number of points in the index.
    function size() external returns (uint256);

    // Inserts a point into the index. Returns false if the point was already in the index
    // and true otherwise.
    function insert(Point memory point) external returns (bool);

    // Removes a point from the index. Returns false if the point was not in the index
    // and true otherwise.
    function remove(Point memory point) external returns (bool);

    // Returns true if the index contains the point.
    function contains(Point memory point) external returns (bool);

    // Returns all points in the index within the given rectangle.
    function searchRect(Rect memory rect) external returns (Point[] memory);

    // Returns the point in the index nearest to the given point or false if the index is empty.
    function nearest(Point memory point) external returns (Point memory, bool);
}
