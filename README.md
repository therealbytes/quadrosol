# Quadrosol

Quadrosol is a Solidity implementation of a quadtree that allows for fast spatial queries on a collection of points within a two-dimensional space.

*This is Concrete app-chain implementation of quadrosol, see the* [`main`](https://github.com/therealbytes/quadrosol/tree/main) *branch for the regular solidity implementation.*

## Installation

`forge install https://github.com/therealbytes/quadrosol`

`npm install https://github.com/therealbytes/quadrosol`

`yarn add https://github.com/therealbytes/quadrosol`

## Usage

```solidity
pragma solidity ^0.8.0;

import {QuadTree, QuadTreeLib, Point, Rect} from "quadrosol/QuadTree.sol";

contract MyContract {
    using QuadTreeLib for QuadTree;
    QuadTree internal tree;

    constructor() {
        Point memory topLeft = Point(0, 0);
        Point memory bottomRight = Point(100, 100);
        Rect memory rect = Rect(topLeft, bottomRight);
        tree.init(rect);
    }

    function addPoint(Point memory point) public {
        tree.add(point);
    }

    function getNearestPoint(
        Point memory point
    ) public view returns (Point memory, bool) {
        return tree.nearest(point);
    }
}
```

## Interface

See [IIndex.sol](src/interfaces/IIndex.sol) for the interface.

## Development

```
git clone https://github.com/therealbytes/quadrosol
cd quadrosol
yarn install
yarn test
yarn benchmark
```

-------

## TODO

- Rigorous testing
- Generalize `nearest` query to `nearestK`
- Add `searchCircle` query
- Add `replace` method
