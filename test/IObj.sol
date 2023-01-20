// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point, Rect} from "../src/Geo.sol";

interface IObj {
    function insert(Point memory point) external returns (bool);

    function remove(Point memory point) external returns (bool);

    function contains(Point memory point) external returns (bool);

    function searchRect(Rect memory rect) external returns (Point[] memory);
}
