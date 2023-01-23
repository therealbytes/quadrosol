// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Point {
    int32 x;
    int32 y;
}

struct Rect {
    Point min;
    Point max;
}

enum Quadrant {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT
}

library MathUtilsLib {
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) public pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) public pure returns (int256) {
        return a < b ? a : b;
    }

    function maxInt32(int32 a, int32 b) public pure returns (int32) {
        return a > b ? a : b;
    }

    function minInt32(int32 a, int32 b) public pure returns (int32) {
        return a < b ? a : b;
    }
}

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
        point.y = int32(int256(data & (2**32 - 1)));
        point.x = int32(int256(data >> 32));
    }
}

library PointsLib {
    function expand(
        Point[] memory points,
        uint256 r
    ) public pure returns (Point[] memory) {
        Point[] memory newPoints = new Point[](points.length * r + 1);
        for (uint256 i = 0; i < points.length; i++) {
            newPoints[i] = points[i];
        }
        return newPoints;
    }

    function expand(
        Point[] memory points
    ) public pure returns (Point[] memory) {
        return expand(points, 2);
    }
}

library RectLib {
    using PointLib for Point;

    function eq(Rect memory a, Rect memory b) public pure returns (bool) {
        return PointLib.eq(a.min, b.min) && PointLib.eq(a.max, b.max);
    }

    function contains(
        Rect memory rect,
        Point memory point
    ) public pure returns (bool) {
        return
            rect.min.x <= point.x &&
            point.x < rect.max.x &&
            rect.min.y <= point.y &&
            point.y < rect.max.y;
    }

    function area(Rect memory rect) public pure returns (uint256) {
        return
            uint256(int256(rect.max.x - rect.min.x)) *
            uint256(int256(rect.max.y - rect.min.y));
    }

    function intersects(
        Rect memory rect,
        Rect memory other
    ) public pure returns (bool) {
        return
            rect.min.x < other.max.x &&
            other.min.x < rect.max.x &&
            rect.min.y < other.max.y &&
            other.min.y < rect.max.y;
    }

    function overlap(
        Rect memory rect,
        Rect memory other
    ) public pure returns (Rect memory) {
        Rect memory overlapRect = Rect({
                min: Point({
                    x: MathUtilsLib.maxInt32(rect.min.x, other.min.x),
                    y: MathUtilsLib.maxInt32(rect.min.y, other.min.y)
                }),
                max: Point({
                    x: MathUtilsLib.minInt32(rect.max.x, other.max.x),
                    y: MathUtilsLib.minInt32(rect.max.y, other.max.y)
                })
            });
        if (overlapRect.min.x >= overlapRect.max.x || overlapRect.min.y >= overlapRect.max.y) {
            return Rect({min: Point({x: 0, y: 0}), max: Point({x: 0, y: 0})});
        }
        return overlapRect;
    }

    function distanceSq(
        Rect memory rect,
        Point memory point
    ) public pure returns (uint256) {
        int32 xd = MathUtilsLib.maxInt32(
            rect.min.x - point.x,
            point.x - rect.max.x
        );
        int32 yd = MathUtilsLib.maxInt32(
            rect.min.y - point.y,
            point.y - rect.max.y
        );
        return uint256(int256(xd * xd + yd * yd));
    }

    function quadrant(
        Rect memory rect,
        Quadrant quad
    ) public pure returns (Rect memory) {
        int32 midX = (rect.min.x + rect.max.x) / 2;
        int32 midY = (rect.min.y + rect.max.y) / 2;
        if (quad == Quadrant.TOP_LEFT) {
            return Rect({min: rect.min, max: Point({x: midX, y: midY})});
        } else if (quad == Quadrant.TOP_RIGHT) {
            return
                Rect({
                    min: Point({x: midX, y: rect.min.y}),
                    max: Point({x: rect.max.x, y: midY})
                });
        } else if (quad == Quadrant.BOTTOM_LEFT) {
            return
                Rect({
                    min: Point({x: rect.min.x, y: midY}),
                    max: Point({x: midX, y: rect.max.y})
                });
        } else if (quad == Quadrant.BOTTOM_RIGHT) {
            return Rect({min: Point({x: midX, y: midY}), max: rect.max});
        }
        revert("RectLib: Invalid quadrant");
    }

    function whichQuadrant(
        Rect memory rect,
        Point memory point
    ) public pure returns (Quadrant) {
        int32 midX = (rect.min.x + rect.max.x) / 2;
        int32 midY = (rect.min.y + rect.max.y) / 2;
        if (point.y < midY) {
            if (point.x < midX) {
                return Quadrant.TOP_LEFT;
            } else {
                return Quadrant.TOP_RIGHT;
            }
        } else {
            if (point.x < midX) {
                return Quadrant.BOTTOM_LEFT;
            } else {
                return Quadrant.BOTTOM_RIGHT;
            }
        }
    }
}
