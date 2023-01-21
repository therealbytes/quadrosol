// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Geo.sol";
import "./Set.sol";

struct SpatialSet {
    Set set;
    Rect rect;
}

library SpatialSetLib {
    using PointLib for Point;
    using RectLib for Rect;

    function size(SpatialSet storage ss) public view returns (uint256) {
        return ss.set.size();
    }

    function insert(
        SpatialSet storage ss,
        Point memory point
    ) public returns (bool) {
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
    ) public returns (bool) {
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
    ) public view returns (bool) {
        return ss.set.has(encodePoint(point));
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

    function searchRect(
        SpatialSet storage ss,
        Rect memory rect
    ) public view returns (Point[] memory) {
        Point[] memory points;

        if (!ss.rect.intersects(rect)) {
            return points;
        }

        uint256 count = 0;
        uint256 setSize = ss.set.size();
        uint256 searchArea = rect.area();

        if (49 * setSize < 37 * searchArea) {
            // Check every point in the set
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
            // Check every point in the search area
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

    function nearest(
        SpatialSet storage ss,
        Point memory point,
        uint256 maxDistance
    ) public view returns (Point memory, bool) {
        if (contains(ss, point)) {
            return (point, true);
        }

        Point memory nearestPoint;
        uint256 minDistanceSq = maxDistance;
        bool haveNearest;
        // Check every point in the set
        for (uint256 i = 0; i < ss.set.size(); i++) {
            (bool ok, uint256 data) = ss.set.getItem(i);
            Point memory p = decodePoint(data);
            uint256 distanceSq = point.distanceSq(p);
            if (distanceSq < minDistanceSq) {
                minDistanceSq = distanceSq;
                nearestPoint = p;
                haveNearest = true;
                if (distanceSq == 0) {
                    break;
                }
            }
        }
        return (nearestPoint, haveNearest);
    }

    function nearest(
        SpatialSet storage ss,
        Point memory point
    ) public view returns (Point memory, bool) {
        return nearest(ss, point, 2 ** 32 - 1);
    }
}
