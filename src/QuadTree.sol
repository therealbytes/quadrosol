// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Geo.sol";

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
    using RectLib for Rect;

    uint256 constant NODE_POINTS = 4;

    function isLeaf(Node storage node) internal view returns (bool) {
        return !node.isInternal;
    }

    function insert(
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
            return insert(node.children[q], rect.quadrant(q), point);
        }
    }

    function subdivide(Node storage node, Rect memory rect) internal {
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

    function contains(
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
            return contains(node.children[q], rect.quadrant(q), point);
        }
    }

    function searchRect(
        Node storage node,
        Rect memory rect,
        Rect memory queryRect,
        Point[] memory points,
        uint256 count
    ) internal view returns (uint256) {
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
}

library QuadTreeLib {
    using RectLib for Rect;
    using NodeLib for Node;

    function size(QuadTree storage qt) public view returns (uint256) {
        return qt._size;
    }

    function insert(QuadTree storage qt, Point memory point)
        internal
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
        internal
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
        internal
        view
        returns (bool)
    {
        if (!qt.rect.contains(point)) {
            return false;
        }
        return qt.root.contains(qt.rect, point);
    }

    function searchRect(QuadTree storage qt, Rect memory rect)
        internal
        view
        returns (Point[] memory)
    {
        Point[] memory tracer = new Point[](0);
        if (!qt.rect.intersects(rect)) {
            return tracer;
        }
        uint256 count = qt.root.searchRect(qt.rect, rect, tracer, 0);
        if (count == 0) {
            return tracer;
        }
        Point[] memory points = new Point[](count);
        qt.root.searchRect(qt.rect, rect, points, 0);
        return points;
    }
}
