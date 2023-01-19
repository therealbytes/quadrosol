// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../src/QuadTree.sol";

import "./Bench.sol";

contract BenchRemove is Bench {
    using QuadTreeLib for QuadTree;
    bytes32 internal rnd;

    function setUp() public override {
        super.setUp();
        for (uint256 i = 0; i < n(); i++) {
            Point memory point = Point(
                int32(int256(randomUint(100))),
                int32(int256(randomUint(100)))
            );
            tree.insert(point);
        }
    }

    function randomUint(uint256 max) internal returns (uint256) {
        rnd = keccak256(abi.encodePacked(rnd));
        return uint256(rnd) % max;
    }

    function precheck() internal override {}

    function action() internal override {
        Point[] memory points = tree.searchRect(
            Rect(Point(25, 25), Point(75, 75))
        );
        console.log("Found %d points", points.length);
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-SearchRect-%d: %d", n(), gas);
    }

    function n() internal view virtual override returns (uint256) {
        return 1000;
    }
}
