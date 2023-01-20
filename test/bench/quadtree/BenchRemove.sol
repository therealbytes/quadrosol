// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Bench.sol";

contract BenchRemove is Bench {
    using QuadTreeLib for QuadTree;

    function action() internal override {
        tree.remove(Point(-1, -1));
    }

    function logResult(uint256 gas) internal override {
        console.log("Benchmark-Remove-%d: %d", n(), gas);
    }

    function n() internal view virtual override returns (uint256) {
        return 0;
    }
}

contract BenchRemove1 is BenchRemove {
    function n() internal view override returns (uint256) {
        return 1;
    }
}

contract BenchRemove10 is BenchRemove {
    function n() internal view override returns (uint256) {
        return 10;
    }
}

contract BenchRemove100 is BenchRemove {
    function n() internal view override returns (uint256) {
        return 100;
    }
}

contract BenchRemove1000 is BenchRemove {
    function n() internal view override returns (uint256) {
        return 1000;
    }
}
