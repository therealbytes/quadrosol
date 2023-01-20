// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Bench.sol";

contract BenchSearchRect5 is Bench {
    using SpatialSetLib for SpatialSet;

    function setUp() public virtual override {
        super.setUp();
        for (uint256 i = 0; i < n(); i++) {
            Point memory point = Point(
                int32(int256(randomUint(10))),
                int32(int256(randomUint(10)))
            );
            set.insert(point);
        }
    }

    function action() internal virtual override {
        set.searchRect(Rect(Point(2, 2), Point(7, 7)));
    }

    function precheck() internal override {}

    function n() internal view virtual override returns (uint256) {
        return 50;
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-SpatialSet-SearchRect-%d: %d", n(), gas);
    }
}

contract BenchSearchRect50 is BenchSearchRect5 {
    using SpatialSetLib for SpatialSet;

    function setUp() public override {
        super.setUp();
        for (uint256 i = 0; i < n(); i++) {
            Point memory point = Point(
                int32(int256(randomUint(100))),
                int32(int256(randomUint(100)))
            );
            set.insert(point);
        }
    }

    function action() internal override {
        set.searchRect(Rect(Point(25, 25), Point(75, 75)));
    }

    function n() internal view virtual override returns (uint256) {
        return 1000;
    }
}
