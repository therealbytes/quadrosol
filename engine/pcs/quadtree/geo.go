package quadtree

import (
	"fmt"
)

// Quadrants
const (
	TopLeft = iota
	TopRight
	BottomLeft
	BottomRight
)

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func abs(a int) int {
	if a < 0 {
		return -a
	}
	return a
}

type Point struct {
	X int
	Y int
}

func (p Point) SquaredDistance(point Point) int {
	dx := p.X - point.X
	dy := p.Y - point.Y
	return dx*dx + dy*dy
}

func (p Point) String() string {
	return fmt.Sprintf("<%d, %d>", p.X, p.Y)
}

type Circle struct {
	C Point
	R int
}

func (c Circle) Top() Point {
	return Point{X: c.C.X, Y: c.C.Y - c.R}
}

func (c Circle) Bottom() Point {
	return Point{X: c.C.X, Y: c.C.Y + c.R}
}

func (c Circle) Left() Point {
	return Point{X: c.C.X - c.R, Y: c.C.Y}
}

func (c Circle) Right() Point {
	return Point{X: c.C.X + c.R, Y: c.C.Y}
}

func (c Circle) Contains(point Point) bool {
	return c.C.SquaredDistance(point) <= c.R*c.R
}

func (c Circle) String() string {
	return fmt.Sprintf("(%d, %d, %d)", c.C.X, c.C.Y, c.R)
}

type Rect struct {
	Min Point
	Max Point
}

func NewRect(x, y, width, height int) Rect {
	return Rect{Min: Point{X: x, Y: y}, Max: Point{X: x + width, Y: y + height}}
}

func NewRectFromPointsLeft(tl, br Point) Rect {
	return Rect{Min: tl, Max: br}
}

func NewRectFromPointsRight(tr, bl Point) Rect {
	return Rect{Min: Point{X: bl.X, Y: tr.Y}, Max: Point{X: tr.X, Y: bl.Y}}
}

func (r Rect) Width() int {
	return r.Max.X - r.Min.X
}

func (r Rect) Height() int {
	return r.Max.Y - r.Min.Y
}

func (r Rect) Size() Point {
	return Point{X: r.Width(), Y: r.Height()}
}

func (r Rect) Center() Point {
	return Point{X: (r.Min.X + r.Max.X) / 2, Y: (r.Min.Y + r.Max.Y) / 2}
}

func (r Rect) TopLeft() Point {
	return r.Min
}

func (r Rect) TopRight() Point {
	return Point{X: r.Max.X, Y: r.Min.Y}
}

func (r Rect) BottomLeft() Point {
	return Point{X: r.Min.X, Y: r.Max.Y}
}

func (r Rect) BottomRight() Point {
	return r.Max
}

func (r Rect) Quadrant(quadrant int) Rect {
	switch quadrant {
	case TopLeft:
		return NewRectFromPointsLeft(r.TopLeft(), r.Center())
	case TopRight:
		return NewRectFromPointsRight(r.TopRight(), r.Center())
	case BottomLeft:
		return NewRectFromPointsRight(r.Center(), r.BottomLeft())
	case BottomRight:
		return NewRectFromPointsLeft(r.Center(), r.BottomRight())
	}
	panic("Invalid quadrant")
}

func (r Rect) Contains(point Point) bool {
	return point.X >= r.Min.X && point.X < r.Max.X && point.Y >= r.Min.Y && point.Y < r.Max.Y
}

func (r Rect) SquaredDistance(point Point) int {
	dx := min(abs(r.Min.X-point.X), abs(r.Max.X-point.X))
	dy := min(abs(r.Min.Y-point.Y), abs(r.Max.Y-point.Y))
	return dx*dx + dy*dy
}

func (r Rect) IntersectsRect(rect Rect) bool {
	return (r.Min.X < rect.Max.X) && (r.Min.Y < rect.Max.Y) && (r.Max.X > rect.Min.X) && (r.Max.Y > rect.Min.Y)
}

func (r Rect) ContainsRect(rect Rect) bool {
	return r.Contains(rect.TopLeft()) && r.Contains(rect.BottomRight())
}

func (r Rect) IntersectsCircle(circle Circle) bool {
	return r.SquaredDistance(circle.C) <= circle.R*circle.R
}

func (r Rect) ContainsCircle(circle Circle) bool {
	// Rect contains circle if the center of the circle is inside the rect
	// and its distance to the rect borders is greater of equal to the radius
	return r.Contains(circle.C) && r.SquaredDistance(circle.C) >= circle.R*circle.R
}

func (r Rect) Overlap(rect Rect) Rect {
	_min := Point{X: max(r.Min.X, rect.Min.X), Y: max(r.Min.Y, rect.Min.Y)}
	_max := Point{X: min(r.Max.X, rect.Max.X), Y: min(r.Max.Y, rect.Max.Y)}
	return Rect{Min: _min, Max: _max}
}

func (r Rect) Union(rect Rect) Rect {
	_min := Point{X: min(r.Min.X, rect.Min.X), Y: min(r.Min.Y, rect.Min.Y)}
	_max := Point{X: max(r.Max.X, rect.Max.X), Y: max(r.Max.Y, rect.Max.Y)}
	return Rect{Min: _min, Max: _max}
}

func (r Rect) WhichQuadrant(point Point) int {
	// Returns the quadrant containing the point
	// If the point is not in the rect, returns the closest quadrant
	center := r.Center()
	if point.X < center.X {
		if point.Y < center.Y {
			return TopLeft
		} else {
			return BottomLeft
		}
	} else {
		if point.Y < center.Y {
			return TopRight
		} else {
			return BottomRight
		}
	}
}

func (r Rect) String() string {
	return fmt.Sprintf("[%s, %d, %d]", r.Min.String(), r.Width(), r.Height())
}
