// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Geo.sol";
import "./Set.sol";

import {IIndex} from "./IIndex.sol";

struct SpatialSet {
    Set set;
    Rect rect;
}

library SpatialSetLib {
    using PointLib for Point;
    using PointsLib for Point[];
    using RectLib for Rect;

    bool internal constant EXPAND_ARRAYS = false;
    bool internal constant USE_SIZE_GUESSES = false;
    uint256 internal constant SIZE_GUESS_RATIO_T10 = 15;

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

    function addPointMatch(
        Point[] memory points,
        Point memory point,
        uint256 count
    ) internal pure returns (Point[] memory) {
        if (EXPAND_ARRAYS && count == points.length && count > 0) {
            points = points.expand();
        }
        if (count < points.length) {
            points[count] = point;
        }
        return points;
    }

    function searchRect(
        SpatialSet storage ss,
        Rect memory rect
    ) public view returns (Point[] memory) {
        Point[] memory points;

        if (!ss.rect.intersects(rect)) {
            return points;
        }

        uint256 setSize = ss.set.size();
        uint256 searchArea = rect.area();

        // The size of the array to put points in
        uint256 arraySize;
        // Number of points in the tree within rect
        uint256 count;
        // Maximum possible count
        uint256 maxCount = MathUtilsLib.min(setSize, searchArea);
        // Uniform distribution expected count times a ratio
        uint256 consCountGuess = 1 +
            (SIZE_GUESS_RATIO_T10 * (setSize * searchArea)) /
            ss.rect.area() /
            10;

        if (USE_SIZE_GUESSES && consCountGuess < maxCount) {
            // Set the array size to a conservative guess
            arraySize = consCountGuess;
        } else {
            // Set the array size to the maximum possible
            arraySize = maxCount;
        }

        // We search once. If the array is too small, we keep counting and search again
        // with an array of the correct size.
        for (uint256 s = 0; s < 2; s++) {
            points = new Point[](arraySize);

            if (49 * setSize < 37 * searchArea) {
                // Check every point in the set
                for (uint256 i = 0; i < setSize; i++) {
                    (bool ok, uint256 data) = ss.set.getItem(i);
                    Point memory point = decodePoint(data);
                    if (rect.contains(point)) {
                        // Re-assign points as array might have been resized
                        points = addPointMatch(points, point, count);
                        count++;
                    }
                }
            } else {
                // Check every point in the search area
                for (int32 x = rect.min.x; x <= rect.max.x; x++) {
                    for (int32 y = rect.min.y; y <= rect.max.y; y++) {
                        Point memory point = Point(x, y);
                        if (ss.set.has(encodePoint(point))) {
                            points = addPointMatch(points, point, count);
                            count++;
                        }
                    }
                }
            }

            if (count > points.length) {
                arraySize = count;
            } else {
                break;
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

contract SpatialSetObj is IIndex {
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

    function searchRect(
        Rect memory rect
    ) external view returns (Point[] memory) {
        return set.searchRect(rect);
    }

    function nearest(
        Point memory point
    ) external view returns (Point memory, bool) {
        return set.nearest(point);
    }
}
