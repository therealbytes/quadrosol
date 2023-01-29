// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Set} from "./Set.sol";

import {Point, PointLib, PointsLib, Rect, RectLib} from "./geo/Index.sol";
import {IIndex} from "./interfaces/IIndex.sol";
import {ISet, ISetRead} from "./interfaces/ISet.sol";
import {MathUtilsLib} from "./utils/MathUtilsLib.sol";

struct SpatialSet {
    ISet set;
    Rect rect;
}

library SpatialSetQueriesLib {
    using PointLib for Point;
    using PointsLib for Point[];
    using RectLib for Rect;

    bool internal constant EXPAND_ARRAYS = false;
    bool internal constant USE_SIZE_GUESSES = false;
    uint256 internal constant SIZE_GUESS_RATIO_T10 = 15;

    function contains(
        ISetRead set,
        Point memory point
    ) public view returns (bool) {
        return set.has(point.encode());
    }

    function searchRect(
        ISetRead set,
        Rect memory setRect,
        Rect memory rect
    ) public view returns (Point[] memory) {
        Point[] memory points;

        if (!setRect.intersects(rect)) {
            return points;
        }

        rect = setRect.overlap(rect);

        uint256 setSize = set.size();
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
            setRect.area() /
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
                    (bool ok, uint256 data) = set.getItem(i);
                    Point memory point;
                    point.decode(data);
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
                        if (set.has(point.encode())) {
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
        ISetRead set,
        Point memory point,
        uint256 maxDistance
    ) public view returns (Point memory, bool) {
        if (contains(set, point)) {
            return (point, true);
        }

        Point memory nearestPoint;
        uint256 minDistanceSq = maxDistance;
        bool haveNearest;
        // Check every point in the set
        for (uint256 i = 0; i < set.size(); i++) {
            (bool ok, uint256 data) = set.getItem(i);
            Point memory p;
            p.decode(data);
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
        ISet set,
        Point memory point
    ) public view returns (Point memory, bool) {
        return nearest(set, point, 2 ** 32 - 1);
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
}

library SpatialSetLib {
    using PointLib for Point;
    using RectLib for Rect;

    function init(SpatialSet storage ss, Rect memory rect) public {
        require(address(ss.set) == address(0), "Already initialized");
        ss.set = ISet(address(new Set()));
        ss.rect = rect;
    }

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
        uint256 data = point.encode();
        if (ss.set.has(data)) {
            return false;
        }
        ss.set.add(data);
        return true;
    }

    function remove(
        SpatialSet storage ss,
        Point memory point
    ) public returns (bool) {
        uint256 data = point.encode();
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
        return SpatialSetQueriesLib.contains(ss.set, point);
    }

    function searchRect(
        SpatialSet storage ss,
        Rect memory rect
    ) public view returns (Point[] memory) {
        return SpatialSetQueriesLib.searchRect(ss.set, ss.rect, rect);
    }

    function nearest(
        SpatialSet storage ss,
        Point memory point
    ) public view returns (Point memory, bool) {
        return SpatialSetQueriesLib.nearest(ss.set, point);
    }

    function nearest(
        SpatialSet storage ss,
        Point memory point,
        uint256 maxDistance
    ) public view returns (Point memory, bool) {
        return SpatialSetQueriesLib.nearest(ss.set, point, maxDistance);
    }
}

contract SpatialSetObj is IIndex {
    using SpatialSetLib for SpatialSet;

    SpatialSet internal set;

    constructor(Rect memory rect) {
        set.init(rect);
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

    // TODO: nearest with maxDistance
}
