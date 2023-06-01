package test

import (
	"testing"

	"github.com/therealbytes/quadrosol/engine/pcs/quadtree"
)

func TestQuadTreeMerkle(t *testing.T) {
	rect := quadtree.NewRect(-5, -5, 10, 10)
	db := quadtree.NewQuadTreeCoreMap()
	qt := quadtree.NewEmptyQuadTreeMerkle(rect, db)
	quadtree.AddQuadTreeMerkle(qt, db)
	TestQuadTreeEmptyLeaf(quadtree.NewQuadTreeMerkleWrap(qt), t)
	TestQuadTreeFullLeaf(quadtree.NewQuadTreeMerkleWrap(qt), t)
}
