// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./IObj.sol";

import {QuadTreeObj} from "./QuadTree.sol";
import {SpatialSetObj} from "./SpatialSet.sol";

abstract contract ObjBench is Test {
    bytes32 internal rnd;
    uint256 internal gu;

    IObj internal obj;
    Rect internal rect;
    string internal name;

    uint256 internal constant RUNS = 32;

    function setUp() public virtual {
        rect = Rect(Point(-10000, -10000), Point(10000, 10000));
        reset();
    }

    function reset() internal virtual;

    function benchInsert(uint256 units) internal {
        insertMany(units);
        startGasMetering();
        populateSquare(10000, RUNS);
        uint256 gas = endGasMetering() / RUNS;
        console.log("Insert-%d: %d", units, gas);
        assertEq(obj.size(), units + RUNS);
    }

    function benchRemove(uint256 units) internal {
        insertMany(units);
        uint256 runs = RUNS;
        if (units < runs) {
            runs = units;
        }
        startGasMetering();
        for (uint256 i = 0; i < runs; i++) {
            obj.remove(pointInDiagonal(i));
        }
        uint256 gas = endGasMetering() / runs;
        console.log("Remove-%d: %d", units, gas);
        assertEq(obj.size(), units - runs);
    }

    function benchContains(uint256 units) internal {
        insertMany(units);
        startGasMetering();
        for (uint256 i = 0; i < RUNS; i++) {
            obj.contains(randomPoint(units));
        }
        uint256 gas = endGasMetering() / RUNS;
        console.log("Contains-%d: %d", units, gas);
    }

    function benchQuery(
        uint256 side,
        uint256 pc,
        uint256 query
    ) internal {
        uint256 units = (side**2 * pc) / 100;
        populateSquare(side, units);
        startGasMetering();
        // TODO: naming
        Point[] memory points = obj.searchRect(
            Rect(pointInDiagonal(uint256(0)), pointInDiagonal(query))
        );
        uint256 gas = endGasMetering();
        // console.log("Query-%d-%d-%d", side, pc, query);
        // console.log("Gas: %d", gas);
        console.log(side, pc, query, gas);
        // uint256 expectedPointsAprox = (units * query**2) / side**2;
        // console.log("Expected points: %d", expectedPointsAprox);
        // console.log("Actual points: %d", points.length);
    }

    function testBenchInsert() public {
        console.log("%s: Insert", name);
        for (uint256 i = 0; i < 4; i++) {
            benchInsert(10**i);
            reset();
        }
    }

    function testBenchRemove() public {
        console.log("%s: Remove", name);
        for (uint256 i = 0; i < 4; i++) {
            benchRemove(10**i);
            reset();
        }
    }

    function testBenchContains() public {
        console.log("%s: Contains", name);
        for (uint256 i = 0; i < 4; i++) {
            benchContains(10**i);
            reset();
        }
    }

    function testBenchQuery() public {
        console.log("%s: Query", name);
        uint8[5] memory percentages = [1, 5, 10, 25, 50];
        for (uint256 i = 3; i < 8; i++) {
            for (uint256 j = 2; j < i; j++) {
                for (uint256 k = 0; k < percentages.length; k++) {
                    benchQuery(2**i, percentages[k], 2 ** j);
                    reset();
                }
            }
        }
    }

    // ================== Helpers ==================

    function startGasMetering() internal {
        gu = gasleft();
    }

    function endGasMetering() internal returns (uint256) {
        return gu - gasleft();
    }

    function randomUint(uint256 max) internal returns (uint256) {
        rnd = keccak256(abi.encodePacked(rnd));
        return uint256(rnd) % max;
    }

    // Generate a random point withing [(0,0), (max, max)]
    function randomPoint(uint256 max) internal returns (Point memory) {
        return
            Point(
                int32(int256(randomUint(max))),
                int32(int256(randomUint(max)))
            );
    }

    // Return a point `(i, i)`
    function pointInDiagonal(int256 i) internal returns (Point memory) {
        return Point(int32(i), int32(i));
    }

    function pointInDiagonal(uint256 i) internal returns (Point memory) {
        return pointInDiagonal(int256(i));
    }

    // Insert points from `(a, a)` to `(b-1, b-1)`, inclusive
    function insertMany(int256 a, int256 b) internal {
        for (int256 i = a; i < b; i++) {
            obj.insert(pointInDiagonal(i));
        }
    }

    function insertMany(uint256 a, uint256 b) internal {
        insertMany(int256(a), int256(b));
    }

    function insertMany(uint256 i) internal {
        uint256 size = obj.size();
        insertMany(size, size + i);
    }

    // Insert `units` random points within a square of side `side` and origin `(0, 0)`
    function populateSquare(uint256 side, uint256 units) internal {
        for (uint256 i = 0; i < units; i++) {
            Point memory point = randomPoint(side);
            obj.insert(point);
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
