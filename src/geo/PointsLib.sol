// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point} from "./Point.sol";

library PointsLib {
    function expand(
        Point[] memory points,
        uint256 r
    ) internal pure returns (Point[] memory) {
        Point[] memory newPoints = new Point[](points.length * r + 1);
        for (uint256 i = 0; i < points.length; i++) {
            newPoints[i] = points[i];
        }
        return newPoints;
    }

    function expand(
        Point[] memory points
    ) internal pure returns (Point[] memory) {
        return expand(points, 2);
    }
}
