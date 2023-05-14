package quadtree

// A generic quadtree implementation. We use this for testing.
type quadTree struct {
	rect   Rect
	points []Point
	quads  []*quadTree
}

func NewQuadTree(rect Rect) *quadTree {
	return &quadTree{
		rect:   rect,
		points: make([]Point, 0),
	}
}

func (qt *quadTree) IsLeaf() bool {
	return len(qt.quads) == 0
}

func (qt *quadTree) Points() []Point {
	return qt.points
}

func (qt *quadTree) Quads() []QuadTree {
	quads := make([]QuadTree, len(qt.quads))
	for ii, quad := range qt.quads {
		quads[ii] = quad
	}
	return quads
}

func (qt *quadTree) GetQuad(quadrant int) QuadTree {
	if qt.IsLeaf() {
		return nil
	}
	return qt.quads[quadrant]
}

func (qt *quadTree) Rect() Rect {
	return qt.rect
}

func (qt *quadTree) Contains(point Point) bool {
	if !qt.rect.Contains(point) {
		return false
	}
	return qt.contains(point)
}

func (qt *quadTree) contains(point Point) bool {
	if qt.IsLeaf() {
		for _, p := range qt.points {
			if p == point {
				return true
			}
		}
		return false
	} else {
		quadrant := qt.rect.WhichQuadrant(point)
		return qt.quads[quadrant].contains(point)
	}
}

func (qt *quadTree) Insert(point Point) bool {
	if !qt.rect.Contains(point) {
		return false
	}
	return qt.insert(point)
}

func (qt *quadTree) insert(point Point) bool {
	if qt.IsLeaf() {
		// Check if point already exists
		if qt.Contains(point) {
			return false
		}
		qt.points = append(qt.points, point)
		if len(qt.points) > 4 {
			qt.split()
			for _, point := range qt.points {
				// We know all the points are in a child quadtree as the were in this one
				quadrant := qt.rect.WhichQuadrant(point)
				qt.quads[quadrant].insert(point)
			}
			qt.points = make([]Point, 0)
		}
		return true
	} else {
		// We know the point is in a child quadtree as it was in this one
		quadrant := qt.rect.WhichQuadrant(point)
		return qt.quads[quadrant].insert(point)
	}
}

func (qt *quadTree) split() {
	qt.quads = make([]*quadTree, 4)
	for ii := 0; ii < 4; ii++ {
		qt.quads[ii] = NewQuadTree(qt.rect.Quadrant(ii))
	}
}

func (qt *quadTree) Remove(point Point) bool {
	if !qt.rect.Contains(point) {
		return false
	}
	return qt.remove(point)
}

func (qt *quadTree) remove(point Point) bool {
	if qt.IsLeaf() {
		for i, p := range qt.points {
			if p == point {
				qt.points = append(qt.points[:i], qt.points[i+1:]...)
				return true
			}
		}
		return false
	} else {
		// We don't need to check if the point is in the quadtree, because
		// we know it is, since we checked it in the parent.
		quadrant := qt.rect.WhichQuadrant(point)
		return qt.quads[quadrant].remove(point)
	}
}
