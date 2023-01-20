// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Geo.sol";
import "./Set.sol";

struct SpatialSet {
    Set set;
    Rect rect;
}

library SpatialSetLib {
    using RectLib for Rect;

    function size(SpatialSet storage ss) external view returns (uint256) {
        return ss.set.size();
    }

    function insert(
        SpatialSet storage ss,
        Point memory point
    ) external returns (bool) {
        if (!ss.rect.contains(point)) {
            return false;
        }
        uint256 data = encodePoint(point);
        if (ss.set.has(data)) {
            return false;
        }
        ss.set.add(encodePoint(point));
        return true;
    }

    function remove(
        SpatialSet storage ss,
        Point memory point
    ) external returns (bool) {
        uint256 data = encodePoint(point);
        if (!ss.set.has(data)) {
            return false;
        }
        ss.set.remove(data);
        return true;
    }

    function contains(
        SpatialSet storage ss,
        Point memory point
    ) external view returns (bool) {
        return ss.set.has(encodePoint(point));
    }

    function searchRect(
        SpatialSet storage ss,
        Rect memory rect
    ) external view returns (Point[] memory) {
        uint256 setSize = ss.set.size();
        uint256 searchArea = rect.area();
        uint256 count = 0;
        Point[] memory points;

        if (setSize < searchArea) {
            points = new Point[](setSize);
            for (uint256 i = 0; i < setSize; i++) {
                (bool ok, uint256 data) = ss.set.getItem(i);
                Point memory point = decodePoint(data);
                if (rect.contains(point)) {
                    points[count] = point;
                    count++;
                }
            }
        } else {
            points = new Point[](searchArea);
            for (int32 x = rect.min.x; x <= rect.max.x; x++) {
                for (int32 y = rect.min.y; y <= rect.max.y; y++) {
                    Point memory point = Point(x, y);
                    if (ss.set.has(encodePoint(point))) {
                        points[count] = point;
                        count++;
                    }
                }
            }
        }

        assembly {
            // resize array
            mstore(points, count)
        }
        return points;
    }

    function encodePoint(Point memory point) internal pure returns (uint256) {
        uint256 data = uint256(int256(point.x));
        data = (data << 32) | uint256(int256(point.y));
        return data;
    }

    function decodePoint(uint256 data) internal pure returns (Point memory) {
        int32 y = int32(int256(data & (2 ** 32 - 1)));
        int32 x = int32(int256(data >> 32));
        return Point(x, y);
    }
}
