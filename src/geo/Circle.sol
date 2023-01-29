// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Point} from "./Point.sol";

struct Circle {
    Point center;
    int32 radius;
}
