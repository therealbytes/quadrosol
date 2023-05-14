// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {PointLib, Point} from "./Point.sol";
import {MathUtilsLib} from "../utils/MathUtilsLib.sol";

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
    using PointLib for Point;

    function eq(Rect memory a, Rect memory b) internal pure returns (bool) {
        return PointLib.eq(a.min, b.min) && PointLib.eq(a.max, b.max);
    }

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

    function area(Rect memory rect) internal pure returns (uint256) {
        return
            uint256(int256(rect.max.x - rect.min.x)) *
            uint256(int256(rect.max.y - rect.min.y));
    }

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

    function overlap(
        Rect memory rect,
        Rect memory other
    ) internal pure returns (Rect memory) {
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
        if (
            overlapRect.min.x >= overlapRect.max.x ||
            overlapRect.min.y >= overlapRect.max.y
        ) {
            return Rect({min: Point({x: 0, y: 0}), max: Point({x: 0, y: 0})});
        }
        return overlapRect;
    }

    function distanceSq(
        Rect memory rect,
        Point memory point
    ) internal pure returns (uint256) {
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
}
