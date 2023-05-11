// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Set as MudSet} from "solecs/Set.sol";

contract Set is MudSet {
    function getItem(uint256 index) public view returns (bool, uint256) {
        if (index >= items.length) return (false, 0);

        return (true, items[index]);
    }
}
