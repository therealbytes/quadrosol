package quadtree

type QuadTree interface {
	Rect() Rect
	IsLeaf() bool
	Contains(point Point) bool
	Points() []Point
	Quads() []QuadTree
	GetQuad(quadrant int) QuadTree
	Insert(point Point) bool
	Remove(point Point) bool
}
