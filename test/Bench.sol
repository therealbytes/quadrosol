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
        reset(1024);
    }

    function reset(uint256 side) internal virtual {
        rect = Rect(Point(0, 0), pointInDiagonal(side));
        reset();
    }

    function reset() internal virtual;

    function benchInsert(uint256 units) internal {
        insertMany(units);
        Point[] memory points = newRandomPoints(RUNS);
        startGasMetering();
        insertPoints(points);
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
        Point[] memory points = newRandomPoints(runs);
        insertPoints(points);
        startGasMetering();
        for (uint256 i = 0; i < runs; i++) {
            obj.remove(points[i]);
        }
        uint256 gas = endGasMetering() / runs;
        console.log("Remove-%d: %d", units, gas);
        assertEq(obj.size(), units);
    }

    function benchContainsYes(uint256 units) internal {
        insertMany(units);
        Point[] memory points = newRandomPoints(RUNS);
        insertPoints(points);
        startGasMetering();
        for (uint256 i = 0; i < RUNS; i++) {
            obj.contains(points[i]);
        }
        uint256 gas = endGasMetering() / RUNS;
        console.log("Contains-%d: %d", units, gas);
    }

    // TODO: benchContainsNo
    // TODO: naming

    function benchQuery(
        uint256 side,
        uint256 pm,
        uint256 query
    ) internal {
        reset(side);
        uint256 units = (side**2 * pm) / 1000;
        insertMany(units);
        Rect memory queryRect = Rect(Point(0, 0), pointInDiagonal(query));
        startGasMetering();
        Point[] memory points = obj.searchRect(queryRect);
        uint256 gas = endGasMetering();
        console.log("Query-%d-%d-%d", side, pm, query);
        console.log("Gas: %d", gas);
        // console.log(side, pm, query, gas);
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
            benchContainsYes(10**i);
            reset();
        }
    }

    function testBenchQuerySmall() public {
        console.log("%s: Query Small", name);
        uint8[4] memory percentages = [1, 3, 9, 12];
        // side exponent
        for (uint256 i = 4; i < 9; i++) {
            // query exponent
            for (uint256 j = 3; j < i - 1; j++) {
                // percentage index
                for (uint256 k = 0; k < percentages.length; k++) {
                    benchQuery(2**i, percentages[k] * 10, 2**j);
                    // reset();
                }
            }
        }
    }

    function testBenchQueryBig() public {
        console.log("%s: Query Big", name);
        benchQuery(2048, 1, 64);
        // reset();
    }

    // ================== Helpers ==================

    function startGasMetering() internal {
        gu = gasleft();
    }

    function endGasMetering() internal view returns (uint256) {
        return gu - gasleft();
    }

    function pointInDiagonal(int256 i) internal pure returns (Point memory) {
        return Point(int32(i), int32(i));
    }

    function pointInDiagonal(uint256 i) internal pure returns (Point memory) {
        return pointInDiagonal(int256(i));
    }

    function randomInt32(int32 min, int32 max) internal returns (int32) {
        rnd = keccak256(abi.encodePacked(rnd));
        return int32(uint32(uint256(rnd)) % uint32(max - min)) + min;
    }

    function randomPoint() internal returns (Point memory) {
        return
            Point(
                randomInt32(rect.min.x, rect.max.x),
                randomInt32(rect.min.y, rect.max.y)
            );
    }

    function newRandomPoint() internal returns (Point memory) {
        Point memory point;
        do {
            point = randomPoint();
        } while (obj.contains(point));
        return point;
    }

    function newRandomPoints(uint256 units) internal returns (Point[] memory) {
        Point[] memory points = new Point[](units);
        for (uint256 i = 0; i < units; i++) {
            points[i] = newRandomPoint();
        }
        return points;
    }

    function insertMany(uint256 units) internal {
        for (uint256 i = 0; i < units; i++) {
            Point memory point = randomPoint();
            // Point memory point = newRandomPoint();
            obj.insert(point);
        }
    }

    function insertPoints(Point[] memory points) internal {
        for (uint256 i = 0; i < points.length; i++) {
            obj.insert(points[i]);
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
