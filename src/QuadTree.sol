// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Geo.sol";

// TODO: Experiment with size tracking
struct Node {
    bool isInternal;
    mapping(Quadrant => Node) children;
    // TODO: How is this laid out in storage?
    Point[] points;
}

struct QuadTree {
    Node root;
    Rect rect;
    uint256 _size;
}

library NodeLib {
    using PointLib for Point;
    using RectLib for Rect;

    uint256 internal constant NODE_POINTS = 4;

    function isLeaf(Node storage node) public view returns (bool) {
        return !node.isInternal;
    }

    function insert(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) public returns (bool) {
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
            return insert(node.children[q], rect.quadrant(q), point);
        }
    }

    function subdivide(Node storage node, Rect memory rect) public {
        node.isInternal = true;
        for (uint256 i = 0; i < node.points.length; i++) {
            insert(node, rect, node.points[i]);
        }
        delete node.points;
    }

    function remove(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) public returns (bool) {
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

    function contains(
        Node storage node,
        Rect memory rect,
        Point memory point
    ) public view returns (bool) {
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
            return contains(node.children[q], rect.quadrant(q), point);
        }
    }

    function searchRect(
        Node storage node,
        Rect memory rect,
        Rect memory queryRect,
        Point[] memory points,
        uint256 count
    ) public view returns (uint256) {
        if (isLeaf(node)) {
            for (uint256 i = 0; i < node.points.length; i++) {
                if (queryRect.contains(node.points[i])) {
                    if (count < points.length) {
                        // We do this so we can search with an array of length 0
                        // to count the number of points
                        points[count] = node.points[i];
                    }
                    count++;
                    // If point.length is 0, we are just counting so we shouldn't stop
                    if (count == points.length) {
                        break;
                    }
                }
            }
            return count;
        } else {
            for (uint256 i = 0; i < 4; i++) {
                Quadrant q = Quadrant(i);
                if (queryRect.intersects(rect.quadrant(q))) {
                    count = searchRect(
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
            return count;
        }
    }

    function nearest(
        Node storage node,
        Rect memory rect,
        Point memory point,
        Point memory nearestPoint,
        uint256 minDistanceSq,
        bool haveNearest
    )
        public
        view
        returns (
            Point memory,
            uint256,
            bool
        )
    {
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

    function size(QuadTree storage qt) public view returns (uint256) {
        return qt._size;
    }

    function insert(QuadTree storage qt, Point memory point)
        public
        returns (bool)
    {
        if (!qt.rect.contains(point)) {
            return false;
        }
        if (qt.root.insert(qt.rect, point)) {
            qt._size++;
            return true;
        }
        return false;
    }

    function remove(QuadTree storage qt, Point memory point)
        public
        returns (bool)
    {
        if (!qt.rect.contains(point)) {
            return false;
        }
        if (qt.root.remove(qt.rect, point)) {
            qt._size--;
            return true;
        }
        return false;
    }

    function contains(QuadTree storage qt, Point memory point)
        public
        view
        returns (bool)
    {
        if (!qt.rect.contains(point)) {
            return false;
        }
        return qt.root.contains(qt.rect, point);
    }

    function searchRect(QuadTree storage qt, Rect memory rect)
        public
        view
        returns (Point[] memory)
    {
        Point[] memory points;
        uint256 arraySize;

        if (!qt.rect.intersects(rect)) {
            return points;
        }

        // Assuming uniform distribution
        // uint256 expectedPoints = (qt._size * rect.area()) / qt.rect.area();

        if (false) {
            arraySize = qt.root.searchRect(qt.rect, rect, new Point[](0), 0);
            if (arraySize == 0) {
                return points;
            }
        } else {
            arraySize = MathUtilsLib.min(qt._size, rect.area());
        }

        points = new Point[](arraySize);
        uint256 count = qt.root.searchRect(qt.rect, rect, points, 0);

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
    ) public view returns (Point memory, bool) {
        (Point memory nearestPoint, uint256 distanceSq, bool haveNearest) = qt
            .root
            .nearest(qt.rect, point, Point(0, 0), maxDistanceSq, false);
        return (nearestPoint, haveNearest);
    }

    function nearest(QuadTree storage qt, Point memory point)
        public
        view
        returns (Point memory, bool)
    {
        return nearest(qt, point, 2**32 - 1);
    }
}
