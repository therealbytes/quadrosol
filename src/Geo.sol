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

library RectLib {
    function contains(
        Rect memory rect,
        Point memory point
    ) internal pure returns (bool) {
        return
            rect.min.x <= point.x &&
            point.x < rect.max.x &&
            rect.min.y <= point.y &&
            point.y < rect.max.y;
    }

    // TODO: wording -- intersects or overlaps?
    function intersects(
        Rect memory rect,
        Rect memory other
    ) internal pure returns (bool) {
        return
            rect.min.x < other.max.x &&
            other.min.x < rect.max.x &&
            rect.min.y < other.max.y &&
            other.min.y < rect.max.y;
    }

    function quadrant(
        Rect memory rect,
        Quadrant quad
    ) internal pure returns (Rect memory) {
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
    ) internal pure returns (Quadrant) {
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

    function area(Rect memory rect) internal pure returns (uint256) {
        return
            uint256(int256(rect.max.x - rect.min.x)) *
            uint256(int256(rect.max.y - rect.min.y));
    }
}
