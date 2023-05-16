// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Point, PointLib, PointsLib, Rect, RectLib, Quadrant} from "./geo/Index.sol";
import {IIndex} from "./interfaces/IIndex.sol";
import {MathUtilsLib} from "./utils/MathUtilsLib.sol";

struct Node {
    bool isInternal;
    mapping(Quadrant => Node) children;
    Point[] points;
}

struct QuadTree {
    Node root;
    Rect rect;
    uint256 _size;
}

library NodeLib {
    using PointLib for Point;
    using PointsLib for Point[];
    using RectLib for Rect;

    uint256 internal constant NODE_POINTS = 4;
    // Wether to expand point arrays when they are full and there are
    bool internal constant EXPAND_ARRAYS = true;

    function isLeaf(Node storage node) internal view returns (bool) {
        return !node.isInternal;
    }

    function add(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) internal returns (bool) {
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                if (
                    node.points[i].x == point.x && node.points[i].y == point.y
                ) {
                    return false;
                }
            }
            node.points.push(point);
            if (node.points.length > NODE_POINTS) {
                subdivide(node, rect);
            }
            return true;
        } else {
            Quadrant q = rect.whichQuadrant(point);
            return add(node.children[q], rect.quadrant(q), point);
        }
    }

    function subdivide(Node storage node, Rect memory rect) internal {
        node.isInternal = true;
        for (uint256 i = 0; i < node.points.length; i++) {
            add(node, rect, node.points[i]);
        }
        delete node.points;
    }

    function remove(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) internal returns (bool) {
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                if (
                    node.points[i].x == point.x && node.points[i].y == point.y
                ) {
                    node.points[i] = node.points[node.points.length - 1];
                    delete node.points[node.points.length - 1];
                    node.points.pop();
                    return true;
                }
            }
            return false;
        } else {
            Quadrant q = rect.whichQuadrant(point);
            return remove(node.children[q], rect.quadrant(q), point);
        }
    }

    function has(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) internal view returns (bool) {
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                if (
                    node.points[i].x == point.x && node.points[i].y == point.y
                ) {
                    return true;
                }
            }
            return false;
        } else {
            Quadrant q = rect.whichQuadrant(point);
            return has(node.children[q], rect.quadrant(q), point);
        }
    }

    function searchRect(
        Node storage node,
        Rect memory rect,
        Rect memory queryRect,
        Point[] memory points,
        uint256 count
    ) internal view returns (uint256, Point[] memory) {
        // Points is returned as it may be expanded
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                if (queryRect.contains(node.points[i])) {
                    // If points.length is 0, this will never be true
                    // We can still use it to count the number of points in the rect
                    if (EXPAND_ARRAYS && count == points.length && count > 0) {
                        points = points.expand();
                    }
                    if (count < points.length) {
                        points[count] = node.points[i];
                    }
                    // Count even if the array is full or length 0
                    count++;
                }
            }
            return (count, points);
        } else {
            for (uint256 i = 0; i < 4; i++) {
                Quadrant q = Quadrant(i);
                if (queryRect.intersects(rect.quadrant(q))) {
                    (count, points) = searchRect(
                        node.children[q],
                        rect.quadrant(q),
                        queryRect,
                        points,
                        count
                    );
                    if (count == points.length) {
                        break;
                    }
                }
            }
            return (count, points);
        }
    }

    function nearest(
        Node storage node,
        Rect memory rect,
        Point memory point,
        Point memory nearestPoint,
        uint256 minDistanceSq,
        bool haveNearest
    ) internal view returns (Point memory, uint256, bool) {
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                uint256 d = point.distanceSq(node.points[i]);
                if (d < minDistanceSq) {
                    nearestPoint = node.points[i];
                    minDistanceSq = d;
                    haveNearest = true;
                }
            }
            return (nearestPoint, minDistanceSq, haveNearest);
        } else {
            // Go down the branch that would contain the point first
            uint256 skip = 5; // Not a quadrant
            if (!haveNearest) {
                // This works even if the point is outside the rect
                Quadrant q = rect.whichQuadrant(point);
                skip = uint256(q);
                (nearestPoint, minDistanceSq, haveNearest) = nearest(
                    node.children[q],
                    rect.quadrant(q),
                    point,
                    nearestPoint,
                    minDistanceSq,
                    haveNearest
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                if (i == skip) {
                    continue;
                }
                Quadrant q = Quadrant(i);
                if (rect.quadrant(q).distanceSq(point) < minDistanceSq) {
                    (nearestPoint, minDistanceSq, haveNearest) = nearest(
                        node.children[q],
                        rect.quadrant(q),
                        point,
                        nearestPoint,
                        minDistanceSq,
                        haveNearest
                    );
                    if (minDistanceSq == 0) {
                        break;
                    }
                }
            }
            return (nearestPoint, minDistanceSq, haveNearest);
        }
    }
}

library QuadTreeLib {
    using RectLib for Rect;
    using NodeLib for Node;

    // Wether to use size guesses to allocate arrays when the expected point count
    // returned by a query is way smaller than the theoretical maximum.
    // This is useful when the the query space is large and the tree is large and sparse.
    bool internal constant USE_SIZE_GUESSES = true;
    // Size guesses are the number of points expected from a uniform distribution times
    // this ratio divided by 10.
    uint256 internal constant SIZE_GUESS_RATIO_T10 = 15;

    function init(QuadTree storage qt, Rect memory rect) internal {
        require(qt._size == 0, "Not empty");
        qt.rect = rect;
    }

    function size(QuadTree storage qt) internal view returns (uint256) {
        return qt._size;
    }

    function add(
        QuadTree storage qt,
        Point memory point
    ) internal returns (bool) {
        if (!qt.rect.contains(point)) {
            return false;
        }
        if (qt.root.add(qt.rect, point)) {
            qt._size++;
            return true;
        }
        return false;
    }

    function remove(
        QuadTree storage qt,
        Point memory point
    ) internal returns (bool) {
        if (!qt.rect.contains(point)) {
            return false;
        }
        if (qt.root.remove(qt.rect, point)) {
            qt._size--;
            return true;
        }
        return false;
    }

    function has(
        QuadTree storage qt,
        Point memory point
    ) internal view returns (bool) {
        if (!qt.rect.contains(point)) {
            return false;
        }
        return qt.root.has(qt.rect, point);
    }

    function searchRect(
        QuadTree storage qt,
        Rect memory rect
    ) internal view returns (Point[] memory) {
        Point[] memory points;
        if (!qt.rect.intersects(rect)) {
            return points;
        }

        // The size of the array to put points in
        uint256 arraySize;
        // Number of points in the tree within rect
        uint256 count;
        // Maximum possible count
        uint256 maxCount = MathUtilsLib.min(qt._size, rect.area());
        // Uniform distribution expected count times a ratio
        uint256 countGuess = 1 +
            (SIZE_GUESS_RATIO_T10 * (qt._size * rect.area())) /
            qt.rect.area() /
            10;

        if (USE_SIZE_GUESSES && countGuess < maxCount) {
            // Set the array size to a conservative guess
            arraySize = countGuess;
        } else {
            // Set the array size to the maximum possible
            arraySize = maxCount;
        }

        // Even if the array is too small, the count is correct
        (count, points) = qt.root.searchRect(
            qt.rect,
            rect,
            new Point[](arraySize),
            0
        );
        // If the array is not dynamically sized, it might be too small
        if (count > points.length) {
            // Create a new array with the correct size and search again
            (count, points) = qt.root.searchRect(
                qt.rect,
                rect,
                new Point[](count),
                0
            );
        }

        assembly {
            // resize array
            mstore(points, count)
        }

        return points;
    }

    function nearest(
        QuadTree storage qt,
        Point memory point,
        uint256 maxDistanceSq
    ) internal view returns (Point memory, bool) {
        (Point memory nearestPoint, , bool haveNearest) = qt
            .root
            .nearest(qt.rect, point, Point(0, 0), maxDistanceSq, false);
        return (nearestPoint, haveNearest);
    }

    function nearest(
        QuadTree storage qt,
        Point memory point
    ) internal view returns (Point memory, bool) {
        return nearest(qt, point, 2 ** 32 - 1);
    }
}

contract QuadTreeObj is IIndex {
    using QuadTreeLib for QuadTree;

    QuadTree internal tree;

    constructor(Rect memory rect) {
        tree.init(rect);
    }

    function size() external view returns (uint256) {
        return tree.size();
    }

    function add(Point memory point) external returns (bool) {
        return tree.add(point);
    }

    function remove(Point memory point) external returns (bool) {
        return tree.remove(point);
    }

    function has(Point memory point) external view returns (bool) {
        return tree.has(point);
    }

    function searchRect(
        Rect memory rect
    ) external view returns (Point[] memory) {
        return tree.searchRect(rect);
    }

    function nearest(
        Point memory point
    ) external view returns (Point memory, bool) {
        return tree.nearest(point);
    }
}

contract QuadTreeMap {
    using QuadTreeLib for QuadTree;

    mapping(uint256 => QuadTree) internal trees;
    uint256 internal nextId;

    function create(Rect memory rect) external returns (uint256) {
        uint256 id = nextId;
        trees[id].init(rect);
        nextId++;
        return id;
    }

    function size(uint256 id) external view returns (uint256) {
        return trees[id].size();
    }

    function add(uint56 id, Point memory point) external returns (bool) {
        return trees[id].add(point);
    }

    function remove(uint256 id, Point memory point) external returns (bool) {
        return trees[id].remove(point);
    }

    function has(uint256 id, Point memory point) external view returns (bool) {
        return trees[id].has(point);
    }

    function searchRect(
        uint256 id, 
        Rect memory rect
    ) external view returns (Point[] memory) {
        return trees[id].searchRect(rect);
    }

    function nearest(
        uint256 id, 
        Point memory point
    ) external view returns (Point memory, bool) {
        return trees[id].nearest(point);
    }
}
