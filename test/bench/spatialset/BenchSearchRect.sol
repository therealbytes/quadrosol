// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./SpatialSetBench.sol";

contract BenchSearchRect5 is SpatialSetBench {
    using SpatialSetLib for SpatialSet;

    function setUp() public virtual override {
        super.setUp();
        populateSquare(side(), n());
    }

    function precheck() internal override {}

    function action() internal virtual override {
        set.searchRect(Rect(Point(2, 2), Point(7, 7)));
    }

    function side() internal view virtual returns (uint256) {
        return 10;
    }

    function n() internal view virtual override returns (uint256) {
        return 50; // 50% full
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-SpatialSet-SearchRect-%d: %d", n(), gas);
    }
}

contract BenchSearchRect16 is BenchSearchRect5 {
    using SpatialSetLib for SpatialSet;

    function action() internal override {
        set.searchRect(Rect(Point(32, 32), Point(48, 48)));
    }

    function side() internal view virtual override returns (uint256) {
        return 128;
    }

    function n() internal view virtual override returns (uint256) {
        return 512; // 2% full
    }
}

contract BenchSearchRect50 is BenchSearchRect5 {
    using SpatialSetLib for SpatialSet;

    function action() internal override {
        set.searchRect(Rect(Point(25, 25), Point(75, 75)));
    }

    function side() internal view virtual override returns (uint256) {
        return 100;
    }

    function n() internal view virtual override returns (uint256) {
        return 1000; // 10% full
    }
}
