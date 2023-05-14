package quadtree

import (
	"strings"

	tg_lib "github.com/ethereum/go-ethereum/tinygo/std"
)

func Contains(qt QuadTree, point Point) bool {
	return contains(qt, point)
}

func contains(qt QuadTree, point Point) bool {
	return qt.Contains(point)
}

func Insert(qt QuadTree, point Point) {
	insert(qt, point)
}

func insert(qt QuadTree, point Point) {
	qt.Insert(point)
}

func Remove(qt QuadTree, point Point) {
	remove(qt, point)
}

func remove(qt QuadTree, point Point) {
	qt.Remove(point)
}

func AllPoints(qt QuadTree) []Point {
	return allPoints(qt)
}

func allPoints(qt QuadTree) []Point {
	if qt.IsLeaf() {
		return qt.Points()
	} else {
		points := make([]Point, 0)
		for _, quad := range qt.Quads() {
			points = append(points, AllPoints(quad)...)
		}
		return points
	}
}

func KNearest(qt QuadTree, point Point, k int) []Point {
	if k <= 0 {
		return make([]Point, 0)
	}
	pq := NewPointPriorityQueue(k)
	pushKNearest(qt, pq, point)
	points := make([]Point, pq.Len())
	for i := len(points) - 1; i >= 0; i-- {
		points[i] = pq.Pop()
	}
	return points
}

func pushKNearest(qt QuadTree, pq *PointPriorityQueue, point Point) {
	// TODO: Go down to the the nearest leaf first, then go up
	if qt.IsLeaf() {
		for _, p := range qt.Points() {
			pq.Push(p, p.SquaredDistance(point))
		}
	} else {
		pushedIdx := -1
		for i := 0; i < 4; i++ {
			if qt.Rect().Quadrant(i).Contains(point) {
				pushKNearest(qt.GetQuad(i), pq, point)
				pushedIdx = i
				break
			}
		}
		for i := 0; i < 4; i++ {
			if i != pushedIdx && (!pq.Full() || qt.Rect().Quadrant(i).IntersectsCircle(Circle{point, pq.PeekPriority()})) {
				pushKNearest(qt.GetQuad(i), pq, point)
			}
		}
	}
}

func SearchRect(qt QuadTree, rect Rect) []Point {
	if !qt.Rect().IntersectsRect(rect) {
		return make([]Point, 0)
	}
	return searchRect(qt, rect)
}

func searchRect(qt QuadTree, rect Rect) []Point {
	if qt.IsLeaf() {
		points := make([]Point, 0)
		for _, point := range qt.Points() {
			if rect.Contains(point) {
				points = append(points, point)
			}
		}
		return points
	} else {
		points := make([]Point, 0)
		for ii := 0; ii < 4; ii++ {
			if qt.Rect().Quadrant(ii).IntersectsRect(rect) {
				points = append(points, searchRect(qt.GetQuad(ii), rect)...)
			}
		}
		return points
	}
}

func SearchCircle(qt QuadTree, circle Circle) []Point {
	if !qt.Rect().IntersectsCircle(circle) {
		return make([]Point, 0)
	}
	return searchCircle(qt, circle)
}

func searchCircle(qt QuadTree, circle Circle) []Point {
	if qt.IsLeaf() {
		points := make([]Point, 0)
		for _, point := range qt.Points() {
			if circle.Contains(point) {
				points = append(points, point)
			}
		}
		return points
	} else {
		points := make([]Point, 0)
		for ii := 0; ii < 4; ii++ {
			if qt.Rect().Quadrant(ii).IntersectsCircle(circle) {
				points = append(points, searchCircle(qt.GetQuad(ii), circle)...)
			}
		}
		return points
	}
}

func Replace(qt QuadTree, point, newPoint Point) (bool, bool) {
	if point == newPoint {
		// Nothing to do.
		return false, false
	}
	if !qt.Rect().Contains(point) {
		// The first point is not in the quadtree, so we just insert the second one.
		return false, qt.Insert(newPoint)
	} else if !qt.Rect().Contains(newPoint) {
		// The second point is not in the quadtree, so we just remove the first one.
		return qt.Remove(point), false
	}
	// Both points are in the quadtree, so we need to remove the first and
	// insert the second.
	return replace(qt, point, newPoint)
}

func replace(qt QuadTree, point, newPoint Point) (bool, bool) {
	// We don't need to check if the point is in the quadtree because we already
	// checked in Replace.
	quadrant := qt.Rect().WhichQuadrant(point)
	newQuadrant := qt.Rect().WhichQuadrant(newPoint)
	if quadrant == newQuadrant && !qt.IsLeaf() {
		// The points are in the same quadrant and we are not at a leaf.
		return replace(qt.GetQuad(quadrant), point, newPoint)
	} else {
		// Either the points are in different quadrants or we are at a leaf.
		return qt.Remove(point), qt.Insert(newPoint)
	}
}

func LeftJoin(qt, quadTree QuadTree) {
	if !qt.Rect().IntersectsRect(quadTree.Rect()) {
		return
	}
	leftJoin(qt, quadTree)
}

func leftJoin(qt, quadTree QuadTree) {
	if quadTree.IsLeaf() {
		for _, point := range quadTree.Points() {
			qt.Insert(point)
		}
	} else if qt.IsLeaf() {
		for _, point := range SearchRect(quadTree, qt.Rect()) {
			qt.Insert(point)
		}
	} else {
		for _, quadLeft := range qt.Quads() {
			if quadLeft.Rect().ContainsRect(quadTree.Rect()) {
				leftJoin(quadLeft, quadTree)
				break
			} else if quadLeft.Rect().IntersectsRect(quadTree.Rect()) {
				for _, quadRight := range quadTree.Quads() {
					leftJoin(quadLeft, quadRight)
				}
			}
		}
	}
}

func PrintQuadTree(qt QuadTree) {
	printQuadTree(qt, 0)
}

func printQuadTree(qt QuadTree, depth int) {
	whiteSpace := strings.Repeat(" ", depth*4)
	rect := qt.Rect()
	tg_lib.Print(whiteSpace, "|_", rect.String())
	if qt.IsLeaf() {
		for _, point := range qt.Points() {
			tg_lib.Print(whiteSpace, "  ", "|_", point.String())
		}
	} else {
		for _, quad := range qt.Quads() {
			printQuadTree(quad, depth+1)
		}
	}
}
