// SPDX-License-Identifier: MIT
// https://github.com/latticexyz/mud/blob/main/packages/solecs/src/Ownable.sol
pragma solidity >=0.8.0;

import {Ownable as SolidStateOwnable} from "lib/solidstate-solidity/contracts/access/ownable/Ownable.sol";
import {OwnableStorage} from "lib/solidstate-solidity/contracts/access/ownable/OwnableStorage.sol";

/**
 * IERC173 implementation
 */
contract Ownable is SolidStateOwnable {
    constructor() {
        // Initialize owner (SolidState has no constructors)
        _setOwner(msg.sender);
    }
}
