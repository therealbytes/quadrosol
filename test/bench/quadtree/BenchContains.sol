// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import "./Bench.sol";

contract BenchContains is Bench {
    using QuadTreeLib for QuadTree;

    function action() internal override {
        tree.contains(Point(-1, -1));
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-Contains-%d: %d", n(), gas);
    }

    function n() internal view virtual override returns (uint256) {
        return 0;
    }
}

contract BenchContains1 is BenchContains {
    function n() internal view override returns (uint256) {
        return 1;
    }
}

contract BenchContains10 is BenchContains {
    function n() internal view override returns (uint256) {
        return 10;
    }
}

contract BenchContains100 is BenchContains {
    function n() internal view override returns (uint256) {
        return 100;
    }
}

contract BenchContains1000 is BenchContains {
    function n() internal view override returns (uint256) {
        return 1000;
    }
}
