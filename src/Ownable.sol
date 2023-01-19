// SPDX-License-Identifier: MIT
// https://github.com/latticexyz/mud/blob/main/packages/solecs/src/Ownable.sol
pragma solidity >=0.8.0;

import { Ownable as SolidStateOwnable } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { OwnableStorage } from "@solidstate/contracts/access/ownable/OwnableStorage.sol";

/**
 * IERC173 implementation
 */
contract Ownable is SolidStateOwnable {
  constructor() {
    // Initialize owner (SolidState has no constructors)
    _setOwner(msg.sender);
  }
}