// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point} from "./Point.sol";

library PointLib {
    function eq(Point memory a, Point memory b) public pure returns (bool) {
        return a.x == b.x && a.y == b.y;
    }

    function distanceSq(
        Point memory a,
        Point memory b
    ) public pure returns (uint256) {
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
