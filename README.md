# Quadrosol

Quadrosol is a quadtree implementation in Solidity that enables efficient spatial queries on a set of points in 2D space.

## Installation

`forge install https://github.com/therealbytes/quadrosol`

## Usage

```solidity
pragma solidity ^0.8.0;

import { QuadTree, QuadTreeLib, Point, Rect } "lib/quadrosol/src/QuadTree.sol";

contract MyContract {
    using QuadTreeLib for QuadTree;
    QuadTree quadtree;

    constructor() {
        quadtree.init(Rect(Point(0, 0), Point(100, 100)));
    }

    function addPoint(Point memory point) public {
        quadtree.add(point);
    }

    function getNearestPoint(Point memory point) public view returns (Point memory, bool) {
        return quadtree.nearest(point);
    }
}
```

## Interface

See [IIndex.sol](src/IIndex.sol) for the full interface.

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
- Add alternative distance functions e.g. manhattan
- Add `searchCircle`
- Add `replace` method