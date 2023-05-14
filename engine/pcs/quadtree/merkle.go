package quadtree

import (
	"encoding/binary"
	"fmt"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	tg_lib "github.com/ethereum/go-ethereum/tinygo/std"
)

func Int32ToBytes(n int32) []byte {
	buf := make([]byte, 4)
	binary.LittleEndian.PutUint32(buf, uint32(n))
	return buf
}

func BytesToInt32(buf []byte) int32 {
	return int32(binary.LittleEndian.Uint32(buf))
}

type QuadTreeCore struct {
	points     []Point
	quadHashes []common.Hash
}

func NewLeafQuadTreeCore(points []Point) *QuadTreeCore {
	return &QuadTreeCore{
		points: points,
	}
}

func NewInternalQuadTreeCore(quadHashes []common.Hash) *QuadTreeCore {
	return &QuadTreeCore{
		quadHashes: quadHashes,
	}
}

func NewEmptyQuadTreeCore() *QuadTreeCore {
	return NewLeafQuadTreeCore(make([]Point, 0))
}

func (core *QuadTreeCore) Points() []Point {
	return core.points
}

func (core *QuadTreeCore) QuadHashes() []common.Hash {
	return core.quadHashes
}

func (core *QuadTreeCore) IsLeaf() bool {
	return len(core.quadHashes) == 0
}

func (core *QuadTreeCore) Encode() []byte {
	if core.IsLeaf() {
		data := make([]byte, 1+len(core.points)*4*2)
		data[0] = byte(len(core.points))
		for ii, point := range core.points {
			idx := 1 + ii*4*2
			xBytes := Int32ToBytes(int32(point.X))
			yBytes := Int32ToBytes(int32(point.Y))
			copy(data[idx:idx+4], xBytes)
			copy(data[idx+4:idx+4+4], yBytes)
		}
		return data
	} else {
		data := make([]byte, 1+4*32)
		data[0] = 0xf0
		for ii, hash := range core.quadHashes {
			idx := 1 + ii*32
			copy(data[idx:idx+32], hash.Bytes())
		}
		return data
	}
}

func (core *QuadTreeCore) Decode(data []byte) {
	if core.points != nil || core.quadHashes != nil {
		panic("Already decoded")
	}
	if len(data) == 0 {
		return
	}
	if data[0] == 0xf0 {
		// Internal
		core.quadHashes = make([]common.Hash, 4)
		for ii := 0; ii < 4; ii++ {
			idx := 1 + ii*32
			core.quadHashes[ii] = common.BytesToHash(data[idx : idx+32])
		}
	} else {
		// Leaf
		core.points = make([]Point, data[0])
		for ii := 0; ii < len(core.points); ii++ {
			idx := 1 + ii*4*2
			x := int(BytesToInt32(data[idx : idx+4]))
			y := int(BytesToInt32(data[idx+4 : idx+4+4]))
			core.points[ii] = Point{X: x, Y: y}
		}
	}
}

func (core *QuadTreeCore) Hash() common.Hash {
	return tg_lib.Keccak256Hash(core.Encode())
}

func (core *QuadTreeCore) String() string {
	if core.IsLeaf() {
		pointsStr := make([]string, len(core.points))
		for ii, point := range core.points {
			pointsStr[ii] = point.String()
		}
		return fmt.Sprintf("[%s]", strings.Join(pointsStr, ", "))
	} else {
		hashesStr := make([]string, len(core.quadHashes))
		for ii, hash := range core.quadHashes {
			hashesStr[ii] = hash.Hex()[2:10]
		}
		return fmt.Sprintf("[%s]", strings.Join(hashesStr, ", "))
	}
}

type QuadTreeCoreDB interface {
	Get(key common.Hash) (*QuadTreeCore, error)
	Put(*QuadTreeCore) (common.Hash, error)
}

type QuadTreeMerkle struct {
	*QuadTreeCore
	hash common.Hash
	rect Rect
	db   QuadTreeCoreDB
}

func NewQuadTreeMerkle(core *QuadTreeCore, rect Rect, db QuadTreeCoreDB) *QuadTreeMerkle {
	return &QuadTreeMerkle{
		QuadTreeCore: core,
		rect:         rect,
		db:           db,
	}
}

func NewEmptyQuadTreeMerkle(rect Rect, db QuadTreeCoreDB) *QuadTreeMerkle {
	return NewQuadTreeMerkle(NewEmptyQuadTreeCore(), rect, db)
}

func AddQuadTreeMerkle(qt *QuadTreeMerkle, db QuadTreeCoreDB) common.Hash {
	hash, err := db.Put(qt.core())
	if err != nil {
		panic(err)
	}
	qt.hash = hash
	return hash
}

func GetQuadTreeMerkle(hash common.Hash, rect Rect, db QuadTreeCoreDB) *QuadTreeMerkle {
	core, err := db.Get(hash)
	if err != nil {
		panic(err)
	}
	return &QuadTreeMerkle{
		QuadTreeCore: core,
		hash:         hash,
		rect:         rect,
		db:           db,
	}
}

func (qt *QuadTreeMerkle) core() *QuadTreeCore {
	return qt.QuadTreeCore
}

func (qt *QuadTreeMerkle) Hash() common.Hash {
	if qt.hash != (common.Hash{}) {
		return qt.hash
	}
	qt.hash = qt.core().Hash()
	return qt.hash
}

func (qt *QuadTreeMerkle) Rect() Rect {
	return qt.rect
}

func (qt *QuadTreeMerkle) Points() []Point {
	return qt.points
}

func (qt *QuadTreeMerkle) DB() QuadTreeCoreDB {
	return qt.db
}

func (qt *QuadTreeMerkle) GetQuad(quadrant int) *QuadTreeMerkle {
	if qt.IsLeaf() {
		return nil
	}
	return qt.getQuad(quadrant)
}

func (qt *QuadTreeMerkle) getQuad(quadrant int) *QuadTreeMerkle {
	hash := qt.quadHashes[quadrant]
	return GetQuadTreeMerkle(hash, qt.rect.Quadrant(quadrant), qt.db)
}

func (qt *QuadTreeMerkle) Quads() []*QuadTreeMerkle {
	quads := make([]*QuadTreeMerkle, len(qt.quadHashes))
	for ii := 0; ii < len(qt.quadHashes); ii++ {
		quads[ii] = qt.getQuad(ii)
	}
	return quads
}

func (qt *QuadTreeMerkle) Contains(point Point) bool {
	if !qt.rect.Contains(point) {
		return false
	}
	return qt.contains(point)
}

func (qt *QuadTreeMerkle) contains(point Point) bool {
	if qt.IsLeaf() {
		for _, p := range qt.points {
			if p == point {
				return true
			}
		}
		return false
	} else {
		quadrant := qt.rect.WhichQuadrant(point)
		return qt.getQuad(quadrant).contains(point)
	}
}

func (qt *QuadTreeMerkle) Insert(point Point) (*QuadTreeMerkle, bool) {
	// If the point is not in the rect, return the hash of the current quadtree, as it is unchanged
	if !qt.rect.Contains(point) {
		return qt, false
	}
	hash := qt.insert(point)
	if hash == qt.Hash() {
		return qt, false
	}
	return GetQuadTreeMerkle(hash, qt.rect, qt.db), true
}

func (qt *QuadTreeMerkle) insert(point Point) common.Hash {
	if qt.IsLeaf() {
		if qt.contains(point) {
			// If the point is already in the quadtree, return the hash of the current quadtree, as it is unchanged
			return qt.Hash()
		}
		if len(qt.points) < 4 {
			// If the leaf has less than 4 points, create a new leaf with the old points and the new one
			points := make([]Point, len(qt.points)+1)
			copy(points, qt.points)
			points[len(qt.points)] = point
			// Create a new quadtree with the new points
			newQt := NewQuadTreeMerkle(NewLeafQuadTreeCore(points), qt.rect, qt.db)
			// Save the new quadtree to the database
			hash := AddQuadTreeMerkle(newQt, qt.db)
			// Return the hash of the new quadtree
			return hash
		} else {
			// If the quadtree has 4 points, split the quadtree into 4 quadtrees
			// Create the 4 new quadtrees
			quads := make([]*QuadTreeMerkle, 4)
			for ii := 0; ii < 4; ii++ {
				quads[ii] = NewEmptyQuadTreeMerkle(qt.rect.Quadrant(ii), qt.db)
			}
			// Add the existing points to the new quadtrees
			for _, pnt := range qt.points {
				// We know that all points are in a quadrant as we checked that the new point is in the rect
				quadrant := qt.rect.WhichQuadrant(pnt)
				quad := quads[quadrant]
				quad.points = append(quad.points, pnt)
			}
			// Save the new quadtrees to the database
			for ii := 0; ii < 4; ii++ {
				AddQuadTreeMerkle(quads[ii], qt.db)
			}
			// Create a new quadtree with the new quadtrees as children
			quadHashes := make([]common.Hash, 4)
			for ii := 0; ii < 4; ii++ {
				quadHashes[ii] = quads[ii].Hash()
			}
			newQt := NewQuadTreeMerkle(NewInternalQuadTreeCore(quadHashes), qt.rect, qt.db)
			// Save the new quadtree to the database
			AddQuadTreeMerkle(newQt, qt.db)
			// Return the hash of the new quadtree holding the four new quadtrees holding
			// the old points and the new point
			return newQt.insert(point)
		}
	} else {
		// If the quadtree is not a leaf, insert the point into the appropriate quadrant
		// We know that the point is in a quadrant as we checked that the new point is in the rect
		quadrant := qt.rect.WhichQuadrant(point)
		quad := qt.getQuad(quadrant)
		quadHash := quad.insert(point)
		// If the hash of the new quadtree is the same as the hash of the old quadtree,
		// return the hash of the current quadtree, as it is unchanged
		if quadHash == quad.Hash() {
			return qt.Hash()
		}
		// If the hash of the new quadtree is different from the hash of the old quadtree,
		// create a new quadtree with the new quadtree in the appropriate quadrant
		quadHashes := make([]common.Hash, 4)
		copy(quadHashes, qt.quadHashes)
		newQt := NewQuadTreeMerkle(NewInternalQuadTreeCore(quadHashes), qt.rect, qt.db)
		newQt.quadHashes[quadrant] = quadHash
		// Save the new quadtree to the database
		hash := AddQuadTreeMerkle(newQt, qt.db)
		// Return the hash of the new quadtree
		return hash
	}
}

// creation and interface methods use. check

func (qt *QuadTreeMerkle) Remove(point Point) (*QuadTreeMerkle, bool) {
	if !qt.rect.Contains(point) {
		return qt, false
	}
	hash := qt.remove(point)
	if hash == qt.Hash() {
		return qt, false
	}
	return GetQuadTreeMerkle(hash, qt.rect, qt.db), true
}

func (qt *QuadTreeMerkle) remove(point Point) common.Hash {
	if qt.IsLeaf() {
		for ii := 0; ii < len(qt.points); ii++ {
			if qt.points[ii] == point {
				// If the point is in the leaf, create a new quadtree with the point removed
				points := make([]Point, len(qt.points)-1)
				copy(points, qt.points[:ii])
				copy(points[ii:], qt.points[ii+1:])
				newQt := NewQuadTreeMerkle(NewLeafQuadTreeCore(points), qt.rect, qt.db)
				hash := AddQuadTreeMerkle(newQt, qt.db)
				return hash
			}
		}
		return qt.Hash()
	} else {
		// We know that the point is in a quadrant as we checked that the point is in the rect
		quadrant := qt.rect.WhichQuadrant(point)
		quad := qt.getQuad(quadrant)
		quadHash := quad.remove(point)
		if quadHash == quad.Hash() {
			return qt.Hash()
		}
		quadHashes := make([]common.Hash, 4)
		copy(quadHashes, qt.quadHashes)
		newQt := NewQuadTreeMerkle(NewInternalQuadTreeCore(quadHashes), qt.rect, qt.db)
		newQt.quadHashes[quadrant] = quadHash
		hash := AddQuadTreeMerkle(newQt, qt.db)
		return hash
	}
}

// We use this for testing
type QuadTreeCoreMap struct {
	M map[common.Hash]*QuadTreeCore
}

func NewQuadTreeCoreMap() *QuadTreeCoreMap {
	return &QuadTreeCoreMap{
		M: make(map[common.Hash]*QuadTreeCore),
	}
}

func (coreMap *QuadTreeCoreMap) Get(key common.Hash) (*QuadTreeCore, error) {
	qt, ok := coreMap.M[key]
	if !ok {
		return nil, fmt.Errorf("not found")
	}
	return qt, nil
}

func (coreMap *QuadTreeCoreMap) Put(qt *QuadTreeCore) (common.Hash, error) {
	hash := qt.Hash()
	if _, ok := coreMap.M[hash]; !ok {
		coreMap.M[hash] = qt
	}
	return hash, nil
}

// We use this for testing
type QuadTreeMerkleWrap struct {
	*QuadTreeMerkle
}

func NewQuadTreeMerkleWrap(qt *QuadTreeMerkle) *QuadTreeMerkleWrap {
	return &QuadTreeMerkleWrap{qt}
}

func (w *QuadTreeMerkleWrap) tree() *QuadTreeMerkle {
	return w.QuadTreeMerkle
}

func (w *QuadTreeMerkleWrap) Quads() []QuadTree {
	quads := w.tree().Quads()
	wraps := make([]QuadTree, len(quads))
	for ii := 0; ii < len(quads); ii++ {
		wraps[ii] = NewQuadTreeMerkleWrap(quads[ii])
	}
	return wraps
}

func (w *QuadTreeMerkleWrap) GetQuad(quadrant int) QuadTree {
	quad := w.tree().GetQuad(quadrant)
	if quad == nil {
		return nil
	}
	return NewQuadTreeMerkleWrap(quad)
}

func (w *QuadTreeMerkleWrap) Insert(point Point) bool {
	qt, ok := w.tree().Insert(point)
	w.QuadTreeMerkle = qt
	return ok
}

func (w *QuadTreeMerkleWrap) Remove(point Point) bool {
	qt, ok := w.tree().Remove(point)
	w.QuadTreeMerkle = qt
	return ok
}
