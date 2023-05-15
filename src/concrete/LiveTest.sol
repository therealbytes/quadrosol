// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {QuadTreeLib, QuadTree} from "./QuadTree.sol";
import {Rect, Point, PointLib} from "../geo/Index.sol";

contract LiveTest {
    using QuadTreeLib for QuadTree;
    using PointLib for Point;

    QuadTree public qt;

    function test() public {
        Rect memory rect = Rect(Point(0, 0), Point(100, 100));

        Point memory point1 = Point(10, 10);
        Point memory point2 = Point(20, 20);
        Point memory point3 = Point(30, 30);
        
        bool ok;
        uint size;

        qt.init(rect);

        // size
        size = qt.size();
        require(size == 0, "expected size == 0");

        // add
        ok = qt.add(point1);
        require(ok, "[1st add] expected ok");

        ok = qt.add(point1);
        require(!ok, "[2nd add] expected !ok");

        size = qt.size();
        require(size == 1, "expected size == 1");

        // has
        ok = qt.has(point1);
        require(ok, "[1st has] expected ok");

        ok = qt.has(point2);
        require(!ok, "[2nd has] expected !ok");

        // search rect
        Rect memory queryRect = Rect(Point(15, 15), Point(35, 35));

        ok = qt.add(point2);
        require(ok, "[3rd add] expected ok");

        ok = qt.add(point3);
        require(ok, "[4rd add] expected ok");

        size = qt.size();
        require(size == 3, "expected size == 3");
        
        Point[] memory points = qt.searchRect(queryRect);
        require(points.length == 2, "expected 2 points");

        require(
            points[0].encode() == point2.encode() ||
                points[0].encode() == point3.encode(),
            "[1st check] expected p2 or p3"
        );

        require(
            points[1].encode() == point2.encode() ||
                points[1].encode() == point3.encode(),
            "[2nd check] expected p2 or p3"
        );

        require(
            points[0].encode() != points[1].encode(),
            "expected 2 different points"
        );
    }
}
