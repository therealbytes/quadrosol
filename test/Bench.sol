// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {Point, Rect, RectLib} from "../src/geo/Index.sol";
import {IIndex} from "../src/interfaces/IIndex.sol";
import {QuadTreeObj} from "../src/QuadTreeLib.sol";
import {SpatialSetObj} from "../src/SpatialSetLib.sol";

abstract contract ObjBench is Test {
    using RectLib for Rect;

    bytes32 internal rnd;
    uint256 internal gu;

    IIndex internal obj;
    Rect internal rect;
    string internal name;

    uint256 internal constant RUNS = 32;

    function setUp() public virtual {
        reset(256);
    }

    function reset(uint256 side) internal virtual {
        rect = Rect(Point(0, 0), pointInDiagonal(side));
        reset();
    }

    function reset() internal virtual;

    function benchAdd(uint256 units) internal virtual {
        addMany(units);
        uint256 startingSize = obj.size();
        Point[] memory points = newRandomPoints(RUNS);
        startGasMetering();
        addPoints(points);
        uint256 gas = endGasMetering() / RUNS;
        console.log("Add-%d: %d", units, gas);
        assertEq(obj.size(), startingSize + RUNS);
    }

    function benchRemove(uint256 units) internal virtual {
        addMany(units);
        uint256 runs = RUNS;
        if (units < runs) {
            runs = units;
        }
        Point[] memory points = newRandomPoints(runs);
        addPoints(points);
        uint256 startingSize = obj.size();
        startGasMetering();
        for (uint256 i = 0; i < runs; i++) {
            obj.remove(points[i]);
        }
        uint256 gas = endGasMetering() / runs;
        console.log("Remove-%d: %d", units, gas);
        assertEq(obj.size(), startingSize - runs);
    }

    function benchHasYes(uint256 units) internal virtual {
        addMany(units);
        Point[] memory points = newRandomPoints(RUNS);
        addPoints(points);
        startGasMetering();
        for (uint256 i = 0; i < RUNS; i++) {
            obj.has(points[i]);
        }
        uint256 gas = endGasMetering() / RUNS;
        console.log("Has-%d: %d", units, gas);
    }

    // TODO: benchHasNo

    function benchSearchRect(uint256 pm, uint256 query) internal virtual {
        uint256 units = (rect.area() * pm) / 1000;
        addMany(units);
        Rect memory queryRect = Rect(Point(0, 0), pointInDiagonal(query));
        startGasMetering();
        obj.searchRect(queryRect);
        uint256 gas = endGasMetering();
        console.log("SearchRect-%d-%d: %d", pm, query, gas);
        console.log(pm, query, gas);
    }

    function benchNearest(uint256 pm) internal virtual {
        uint256 units = (rect.area() * pm) / 1000;
        addMany(units);
        Point[] memory points = newRandomPoints(RUNS);
        startGasMetering();
        for (uint256 i = 0; i < RUNS; i++) {
            obj.nearest(points[i]);
        }
        uint256 gas = endGasMetering() / RUNS;
        console.log("Nearest-%d: %d", pm, gas);
    }

    function testBenchAdd() public virtual {
        console.log("%s: Add", name);
        for (uint256 i = 0; i < 4; i++) {
            benchAdd(10**i);
            reset();
        }
    }

    function testBenchRemove() public virtual {
        console.log("%s: Remove", name);
        for (uint256 i = 0; i < 4; i++) {
            benchRemove(10**i);
            reset();
        }
    }

    function testBenchHas() public virtual {
        console.log("%s: Has", name);
        for (uint256 i = 0; i < 4; i++) {
            benchHasYes(10**i);
            reset();
        }
    }

    function testBenchSearchRect256Dense() public virtual {
        console.log("%s: SearchRect 256Dense", name);
        // percentage exponent
        for (uint256 i = 0; i < 3; i++) {
            // query exponent
            for (uint256 j = 2; j < 7; j++) {
                benchSearchRect(3**i * 10, 2**j);
                reset();
            }
        }
    }

    function testBenchSearchRect1024Sparse() public virtual {
        reset(1024);
        console.log("%s: SearchRect 1024Sparse", name);
        // percentage exponent
        for (uint256 i = 0; i < 3; i++) {
            // query exponent
            for (uint256 j = 2; j < 9; j++) {
                benchSearchRect(3**i, 2**j);
                reset();
            }
        }
    }

    function testBenchNearest256Dense() public virtual {
        console.log("%s: Nearest 256Dense", name);
        // percentage exponent
        for (uint256 i = 0; i < 3; i++) {
            benchNearest(3**i * 10);
            reset();
        }
    }

    function testBenchNearest1024Sparse() public virtual {
        reset(1024);
        console.log("%s: Nearest 1024Sparse", name);
        // percentage exponent
        for (uint256 i = 0; i < 3; i++) {
            benchNearest(3**i);
            reset();
        }
    }

    // ================== Helpers ==================

    function startGasMetering() internal virtual {
        gu = gasleft();
    }

    function endGasMetering() internal view virtual returns (uint256) {
        return gu - gasleft();
    }

    function pointInDiagonal(int256 i) internal pure virtual returns (Point memory) {
        return Point(int32(i), int32(i));
    }

    function pointInDiagonal(uint256 i) internal pure virtual returns (Point memory) {
        return pointInDiagonal(int256(i));
    }

    function randomInt32(int32 min, int32 max) internal virtual returns (int32) {
        rnd = keccak256(abi.encodePacked(rnd));
        return int32(uint32(uint256(rnd)) % uint32(max - min)) + min;
    }

    function randomPoint() internal virtual returns (Point memory) {
        return
            Point(
                randomInt32(rect.min.x, rect.max.x),
                randomInt32(rect.min.y, rect.max.y)
            );
    }

    function newRandomPoint() internal virtual returns (Point memory) {
        Point memory point;
        do {
            point = randomPoint();
        } while (obj.has(point));
        return point;
    }

    function newRandomPoints(uint256 units) internal virtual returns (Point[] memory) {
        Point[] memory points = new Point[](units);
        for (uint256 i = 0; i < units; i++) {
            points[i] = newRandomPoint();
        }
        return points;
    }

    function addMany(uint256 units) internal virtual {
        for (uint256 i = 0; i < units; i++) {
            Point memory point = randomPoint();
            // Point memory point = newRandomPoint();
            obj.add(point);
        }
    }

    function addPoints(Point[] memory points) internal virtual {
        for (uint256 i = 0; i < points.length; i++) {
            obj.add(points[i]);
        }
    }
}

contract QuadTreeTest is ObjBench {
    function setUp() public override {
        name = "QuadTree";
        super.setUp();
    }

    function reset() internal override {
        obj = new QuadTreeObj(rect);
    }
}

contract SpatialSetTest is ObjBench {
    function setUp() public override {
        name = "SpatialSet";
        super.setUp();
    }

    function reset() internal override {
        obj = new SpatialSetObj(rect);
    }
}
