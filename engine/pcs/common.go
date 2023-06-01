package pcs

import (
	"math/big"

	"github.com/therealbytes/quadrosol/engine/pcs/quadtree"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/math"
	cc_api "github.com/ethereum/go-ethereum/concrete/api"
)

func EncodeRect(rect quadtree.Rect) []byte {
	data := make([]byte, 16)
	copy(data[0:4], quadtree.Int32ToBytes(int32(rect.Min.X)))
	copy(data[4:8], quadtree.Int32ToBytes(int32(rect.Min.Y)))
	copy(data[8:12], quadtree.Int32ToBytes(int32(rect.Width())))
	copy(data[12:16], quadtree.Int32ToBytes(int32(rect.Height())))
	return data
}

func DecodeRect(data []byte) quadtree.Rect {
	if len(data) != 16 {
		return quadtree.Rect{}
	}
	return quadtree.NewRect(
		int(quadtree.BytesToInt32(data[0:4])),
		int(quadtree.BytesToInt32(data[4:8])),
		int(quadtree.BytesToInt32(data[8:12])),
		int(quadtree.BytesToInt32(data[12:16])),
	)
}

func EvmEncodeInt(i int) []byte {
	return math.U256Bytes(big.NewInt(int64(i)))
}

func EvmDecodeInt(data []byte) int {
	return int(math.S256(new(big.Int).SetBytes(data)).Int64())
}

func EvmEncodePoint(point quadtree.Point) []byte {
	data := make([]byte, EvmPointSize)
	copy(data[:EvmIntSize], EvmEncodeInt(point.X))
	copy(data[EvmIntSize:], EvmEncodeInt(point.Y))
	return data
}

func EvmDecodePoint(data []byte) quadtree.Point {
	if len(data) != int(EvmPointSize) {
		return quadtree.Point{}
	}
	return quadtree.Point{
		X: EvmDecodeInt(data[:EvmIntSize]),
		Y: EvmDecodeInt(data[EvmIntSize:]),
	}
}

func EvmEncodePoints(points []quadtree.Point) []byte {
	data := make([]byte, 32+int(EvmPointSize)*len(points))
	copy(data[:32], EvmEncodeInt(len(points)))
	for i, point := range points {
		copy(data[32+int(EvmPointSize)*i:32+int(EvmPointSize)*(i+1)], EvmEncodePoint(point))
	}
	return data
}

func EvmDecodePoints(data []byte) []quadtree.Point {
	if len(data) < 32 {
		return nil
	}
	numPoints := EvmDecodeInt(data[:32])
	if len(data) != 32+int(EvmPointSize)*numPoints {
		return nil
	}
	points := make([]quadtree.Point, numPoints)
	for i := range points {
		points[i] = EvmDecodePoint(data[32+int(EvmPointSize)*i : 32+int(EvmPointSize)*(i+1)])
	}
	return points
}

func EvmEncodeRect(rect quadtree.Rect) []byte {
	data := make([]byte, EvmRectSize)
	copy(data[:EvmPointSize], EvmEncodePoint(rect.Min))
	copy(data[EvmPointSize:], EvmEncodePoint(rect.Max))
	return data
}

func EvmDecodeRect(data []byte) quadtree.Rect {
	if len(data) != int(EvmRectSize) {
		return quadtree.Rect{}
	}
	return quadtree.NewRectFromPointsLeft(
		EvmDecodePoint(data[:EvmPointSize]),
		EvmDecodePoint(data[EvmPointSize:]),
	)
}

type DirtiesTracker struct {
	m cc_api.Mapping
	s cc_api.Set
}

func NewDirtyTracker(ds cc_api.Datastore, id common.Hash) DirtiesTracker {
	return DirtiesTracker{
		m: ds.NewMap(id),
		s: ds.NewSet(common.BigToHash(new(big.Int).Add(id.Big(), common.Big1))),
	}
}

func (t DirtiesTracker) get(key common.Hash) *big.Int {
	return t.m.Get(key).Big()
}

func (t DirtiesTracker) set(key common.Hash, value *big.Int) {
	t.m.Set(key, common.BigToHash(value))
}

func (t DirtiesTracker) Inc(key common.Hash) {
	t.set(key, t.get(key).Add(t.get(key), common.Big1))
	t.s.Add(key)
}

func (t DirtiesTracker) Dec(key common.Hash) {
	dirties := t.get(key)
	if dirties.Cmp(common.Big0) == 0 {
		return
	}
	if dirties.Cmp(common.Big1) == 0 {
		t.m.Set(key, common.Hash{})
		t.s.Remove(key)
		return
	}
	t.set(key, dirties.Sub(dirties, common.Big1))
}

func (t DirtiesTracker) Dirties() cc_api.Array {
	return t.s.Values()
}
