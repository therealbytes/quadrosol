package test

import (
	"concrete-quad/engine/pcs/quadtree"
	"testing"
)

func AssertLeaf(qt quadtree.QuadTree, t *testing.T) {
	if !qt.IsLeaf() {
		t.Error("Expected leaf node")
	}
	if len(qt.Quads()) != 0 {
		t.Error("Expected no quads, got", qt.Quads())
	}
	for i := 0; i < 4; i++ {
		if qt.GetQuad(i) != nil {
			t.Error("Expected nil quad, got", qt.GetQuad(i))
		}
	}
}

func AssertNotLeaf(qt quadtree.QuadTree, t *testing.T) {
	if qt.IsLeaf() {
		t.Error("Expected internal node")
	}
	if len(qt.Points()) != 0 {
		t.Error("Expected no points, got", qt.Points())
	}
	if len(qt.Quads()) != 4 {
		t.Error("Expected quads")
	}
	for i := 0; i < 4; i++ {
		if qt.GetQuad(i) == nil {
			t.Error("Expected quad")
		}
	}
}

func TestQuadTreeEmptyLeaf(qt quadtree.QuadTree, t *testing.T) {
	expectedRect := quadtree.NewRect(-5, -5, 10, 10)
	if qt.Rect() != expectedRect {
		t.Error("Expected rect to be", expectedRect)
	}

	AssertLeaf(qt, t)

	if len(qt.Points()) != 0 {
		t.Error("Expected no points, got", qt.Points())
	}

	qt.Insert(quadtree.Point{X: 0, Y: 0})
	qt.Insert(quadtree.Point{X: 1, Y: 1})
	qt.Insert(quadtree.Point{X: 2, Y: 2})
	qt.Insert(quadtree.Point{X: 3, Y: 3})
	qt.Insert(quadtree.Point{X: 10, Y: 10}) // Out of bounds
	AssertLeaf(qt, t)

	if len(qt.Points()) != 4 {
		t.Error("Expected points")
	}

	if !qt.Contains(quadtree.Point{X: 0, Y: 0}) {
		t.Error("Expected to contain point")
	}
	if qt.Contains(quadtree.Point{X: -1, Y: -1}) {
		t.Error("Expected not to contain point")
	}
	if qt.Contains(quadtree.Point{X: 10, Y: 10}) {
		t.Error("Expected not to contain point")
	}

	qt.Remove(quadtree.Point{X: 0, Y: 0})
	qt.Remove(quadtree.Point{X: 2, Y: 2})
	qt.Remove(quadtree.Point{X: 10, Y: 10}) // Out of bounds
	AssertLeaf(qt, t)

	if len(qt.Points()) != 2 {
		t.Error("Expected no points, got", qt.Points())
	}

	qt.Remove(quadtree.Point{X: 1, Y: 1})
	qt.Remove(quadtree.Point{X: 3, Y: 3})
	AssertLeaf(qt, t)

	if len(qt.Points()) != 0 {
		t.Error("Expected no points, got", qt.Points())
	}
}

func TestQuadTreeFullLeaf(qt quadtree.QuadTree, t *testing.T) {
	expectedRect := quadtree.NewRect(-5, -5, 10, 10)
	if qt.Rect() != expectedRect {
		t.Error("Expected rect to be", expectedRect)
	}

	qt.Insert(quadtree.Point{X: 0, Y: 0})
	qt.Insert(quadtree.Point{X: 1, Y: 1})
	qt.Insert(quadtree.Point{X: 2, Y: 2})
	qt.Insert(quadtree.Point{X: 3, Y: 3})
	qt.Insert(quadtree.Point{X: 10, Y: 10}) // Out of bounds

	if !qt.Contains(quadtree.Point{X: 0, Y: 0}) {
		t.Error("Expected to contain point")
	}
	if qt.Contains(quadtree.Point{X: -1, Y: -1}) {
		t.Error("Expected not to contain point")
	}
	if qt.Contains(quadtree.Point{X: 10, Y: 10}) {
		t.Error("Expected not to contain point")
	}

	quadtree.PrintQuadTree(qt)

	qt.Insert(quadtree.Point{X: 4, Y: 4})
	qt.Insert(quadtree.Point{X: 5, Y: 5})
	AssertNotLeaf(qt, t)

	quadtree.PrintQuadTree(qt)

	for i := 0; i < 3; i++ {
		AssertLeaf(qt.GetQuad(i), t)
	}

	AssertNotLeaf(qt.GetQuad(3), t)

	qt.Remove(quadtree.Point{X: 0, Y: 0})
	qt.Remove(quadtree.Point{X: 1, Y: 1})
	qt.Remove(quadtree.Point{X: 10, Y: 10}) // Out of bounds
	AssertNotLeaf(qt, t)
}
