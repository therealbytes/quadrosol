// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Point {
    int32 x;
    int32 y;
}

library PointLib {
    function eq(Point memory a, Point memory b) internal pure returns (bool) {
        return a.x == b.x && a.y == b.y;
    }

    function distanceSq(
        Point memory a,
        Point memory b
    ) internal pure returns (uint256) {
        return
            uint256(
                int256((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
            );
    }

    function encode(Point memory point) internal pure returns (uint256) {
        uint256 data = uint256(int256(point.x));
        data = (data << 32) | uint256(int256(point.y));
        return data;
    }

    function decode(Point memory point, uint256 data) internal pure {
        point.y = int32(int256(data & (2 ** 32 - 1)));
        point.x = int32(int256(data >> 32));
    }
}

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
