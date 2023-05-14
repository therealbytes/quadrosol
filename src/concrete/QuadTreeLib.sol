// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MemLib} from "pclib/MemLib.sol";
import {Caller} from "pclib/Caller.sol";
import {Rect, Point} from "../geo/Index.sol";

enum OpQuadDB {
    Create,
    Delete,
    Duplicate,
    Read,
    Add,
    Remove,
    Replace,
    Has,
    KNearest,
    SearchRect,
    SearchCircle
}

library QuadDBLib {
    address constant pc = address(0x80);

    function create(Rect memory rect) internal returns (uint256 id) {
        uint256 o = MemLib.getFmp();
        uint256 p = MemLib.putUint(o, uint256(OpQuadDB.Create));
        p = putRect(p, rect);
        call(o, p, 0x20);
        (id, ) = MemLib.getUint(o);
        return id;
    }

    function read(
        uint256 id
    ) internal view returns (bytes32 _hash, uint256 size, Rect memory rect) {
        uint256 o = MemLib.getFmp();
        uint256 p = MemLib.putUint(o, uint256(OpQuadDB.Read));
        p = MemLib.putUint(p, id);
        uint256 r = 0x20 + 2 * 2 * 0x20 + 0x20;
        staticcall(o, p, r);
        MemLib.setFmp(o + r);
        (_hash, p) = MemLib.getBytes32(o);
        (size, p) = MemLib.getUint(p);
        (rect, ) = refRect(p);
        return (_hash, size, rect);
    }

    function add(uint256 id, Point memory point) internal returns (bool ok) {
        uint256 o = MemLib.getFmp();
        uint p = MemLib.putUint(o, uint256(OpQuadDB.Add));
        p = MemLib.putUint(p, id);
        p = putPoint(p, point);
        call(o, p, 0x20);
        (ok, ) = MemLib.getBool(o);
        return ok;
    }

    function has(
        uint256 id,
        Point memory point
    ) internal view returns (bool ok) {
        uint256 o = MemLib.getFmp();
        uint p = MemLib.putUint(o, uint256(OpQuadDB.Has));
        p = MemLib.putUint(p, id);
        p = putPoint(p, point);
        staticcall(o, p, 0x20);
        (ok, ) = MemLib.getBool(o);
        return ok;
    }

    function searchRect(
        uint256 id,
        Rect memory rect,
        uint256 k
    ) internal view returns (Point[] memory points) {
        uint256 o = MemLib.getFmp();
        uint p = MemLib.putUint(o, uint256(OpQuadDB.SearchRect));
        p = MemLib.putUint(p, id);
        p = putRect(p, rect);
        uint256 r = 0x20 + k * 2 * 0x20;
        staticcall(o, p, r);
        uint256 size;
        (size, p) = MemLib.getUint(o);
        MemLib.setFmp(o + 0x20 + size * 2 * 0x20);
        (points, p) = refPoints(o);
        return points;
    }

    function call(uint256 o, uint256 p, uint256 outSize) internal {
        uint256 gas = (gasleft() * 9) / 10;
        Caller.call(gas, pc, 0, o, p - o, o, outSize);
    }

    function staticcall(uint256 o, uint256 p, uint256 outSize) internal view {
        uint256 gas = (gasleft() * 9) / 10;
        Caller.staticcall(gas, pc, o, p - o, o, outSize);
    }

    function putPoint(
        uint256 p,
        Point memory point
    ) internal pure returns (uint256) {
        p = MemLib.putInt(p, int256(point.x));
        p = MemLib.putInt(p, int256(point.y));
        return p;
    }

    function copyPoint(
        uint256 p
    ) internal pure returns (Point memory point, uint256) {
        int256 x;
        int256 y;
        (x, p) = MemLib.getInt(p);
        (y, p) = MemLib.getInt(p);
        point.x = int32(int256(x));
        point.y = int32(int256(y));
        return (point, p);
    }

    function refPoint(
        uint256 r
    ) internal pure returns (Point memory point, uint256) {
        assembly {
            point := r
        }
        return (point, r + 2 * 0x20);
    }

    function refPoints(
        uint256 r
    ) internal pure returns (Point[] memory points, uint256) {
        uint256 size;
        (size, r) = MemLib.getUint(r);
        points = new Point[](size);
        uint256 p;
        assembly {
            p := points
        }
        p += 0x20;
        for (uint256 i = 0; i < size; i++) {
            p = MemLib.putUint(p, r + i * 2 * 0x20);
        }
        return (points, p);
    }

    function putRect(
        uint256 p,
        Rect memory rect
    ) internal pure returns (uint256) {
        p = putPoint(p, rect.min);
        p = putPoint(p, rect.max);
        return p;
    }

    function refRect(
        uint256 r
    ) internal pure returns (Rect memory rect, uint256) {
        (rect.min, r) = refPoint(r);
        (rect.max, r) = refPoint(r);
        return (rect, r);
    }
}

struct QuadTree {
    uint256 id;
}

library QuadTreeLib {
    function init(QuadTree storage qt, Rect memory rect) internal {
        qt.id = QuadDBLib.create(rect);
    }

    function size(QuadTree storage qt) internal view returns (uint256) {
        (, uint256 _size, ) = QuadDBLib.read(qt.id);
        return _size;
    }

    function add(
        QuadTree storage qt,
        Point memory point
    ) internal returns (bool) {
        return QuadDBLib.add(qt.id, point);
    }

    function remove(
        QuadTree storage qt,
        Point memory point
    ) internal returns (bool) {
        revert("not implemented");
    }

    function has(
        QuadTree storage qt,
        Point memory point
    ) internal view returns (bool) {
        return QuadDBLib.has(qt.id, point);
    }

    function searchRect(
        QuadTree storage qt,
        Rect memory rect
    ) internal view returns (Point[] memory) {
        uint256 countGuess = size(qt);
        Point[] memory points = QuadDBLib.searchRect(qt.id, rect, countGuess);
        if (points.length <= countGuess) {
            return points;
        }
        // Underestimated the number of points in the rect, try again with the
        // correct number
        // This won't happen if we use size() as countGuess
        return QuadDBLib.searchRect(qt.id, rect, points.length);
    }

    function nearest(
        QuadTree storage qt,
        Point memory point
    ) internal view returns (Point memory, bool) {
        revert("not implemented");
    }
}
