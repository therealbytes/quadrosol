package test

import (
	"concrete-quad/engine/pcs/quadtree"
	"testing"
)

func TestQuadTree(t *testing.T) {
	rect := quadtree.NewRect(-5, -5, 10, 10)
	TestQuadTreeEmptyLeaf(quadtree.NewQuadTree(rect), t)
	TestQuadTreeFullLeaf(quadtree.NewQuadTree(rect), t)
}
