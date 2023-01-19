// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import "./Bench.sol";

contract BenchInsert is Bench {
    using QuadTreeLib for QuadTree;

    function action() internal override {
        insertMany(-32, 0);
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-Insert-%d: %d", n(), gas);
    }

    function n() internal view virtual override returns (uint256) {
        return 0;
    }
}

contract BenchInsert1 is BenchInsert {
    function n() internal view override returns (uint256) {
        return 1;
    }
}

contract BenchInsert10 is BenchInsert {
    function n() internal view override returns (uint256) {
        return 10;
    }
}

contract BenchInsert100 is BenchInsert {
    function n() internal view override returns (uint256) {
        return 100;
    }
}

contract BenchInsert1000 is BenchInsert {
    function n() internal view override returns (uint256) {
        return 1000;
    }
}
