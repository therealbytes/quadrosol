package test

import (
	"concrete-quad/engine/pcs"
	"concrete-quad/engine/pcs/quadtree"
	_ "embed"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/concrete/contracts"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/stretchr/testify/require"
)

func TestQuadDB(t *testing.T) {
	r := require.New(t)
	wpc := QuadPCWrapper{pcs.QuadDBPrecompile}
	api := NewTestAPI()

	// create
	rect := quadtree.NewRect(-50, -50, 100, 100)
	for ii := 0; ii < 8; ii++ {
		id, err := wpc.Create(api, rect)
		r.NoError(err)
		r.Equal(ii, id)
	}

	// read
	id := 0
	_, readSize, readRect, err := wpc.Read(api, id)
	r.NoError(err)
	r.Equal(0, readSize)
	r.Equal(rect, readRect)

	// add
	points := []quadtree.Point{
		{X: -7, Y: -6}, {X: -5, Y: -4}, {X: -3, Y: -2}, {X: -1, Y: 0},
		{X: 1, Y: 2}, {X: 3, Y: 4}, {X: 5, Y: 6}, {X: 7, Y: 8},
	}
	for _, point := range points {
		ok, err := wpc.Add(api, id, point)
		r.NoError(err)
		r.True(ok)
	}
	for _, point := range points {
		ok, err := wpc.Add(api, id, point)
		r.NoError(err)
		r.False(ok)
	}
	_, readSize, _, err = wpc.Read(api, id)
	r.NoError(err)
	r.Equal(len(points), readSize)

	// has
	for _, point := range points {
		ok, err := wpc.Has(api, id, point)
		r.NoError(err)
		r.True(ok)
	}
	ok, err := wpc.Has(api, id, quadtree.Point{X: 20, Y: 20})
	r.NoError(err)
	r.False(ok)
	ok, err = wpc.Has(api, id, quadtree.Point{X: 100, Y: 100})
	r.NoError(err)
	r.False(ok)

	// searchRect
	queryRect := quadtree.NewRect(-3, -3, 5, 5)
	expectedPoints := make([]quadtree.Point, 0)
	for _, point := range points {
		if queryRect.Contains(point) {
			expectedPoints = append(expectedPoints, point)
		}
	}
	foundPoints, err := wpc.SearchRect(api, id, queryRect)
	r.NoError(err)
	r.Equal(len(expectedPoints), len(foundPoints))
	r.EqualValues(expectedPoints, foundPoints)
}

func TestQuadDBAcrossCommits(t *testing.T) {
	wpc := QuadPCWrapper{pcs.QuadDBPrecompile}
	rect := quadtree.NewRect(-50, -50, 100, 100)
	point := quadtree.Point{X: -7, Y: -6}
	address := common.HexToAddress("0xc0ffee")
	contracts.AddPrecompile(address, pcs.QuadDBPrecompile)

	db := state.NewDatabase(rawdb.NewMemoryDatabase())

	// State 0
	state0, _ := state.New(common.Hash{}, db, nil)
	state0.SetBalance(address, common.Big1)
	state0Root, err := state0.Commit(true)
	require.NoError(t, err)

	// State 1
	state1, _ := state.New(state0Root, db, nil)
	api1 := NewTestAPIWithStateDB(state1, address)

	id, err := wpc.Create(api1, rect)
	require.NoError(t, err)

	ok, err := wpc.Add(api1, id, point)
	require.NoError(t, err)
	require.True(t, ok)

	state1Root, err := state1.Commit(true)
	require.NoError(t, err)

	// State 2
	state2, _ := state.New(state1Root, db, nil)
	api2 := NewTestAPIWithStateDB(state2, address)

	_, size, _rect, err := wpc.Read(api2, id)
	require.NoError(t, err)
	require.Equal(t, 1, size)
	require.Equal(t, rect, _rect)

	ok, err = wpc.Has(api2, id, point)

	require.NoError(t, err)
	require.True(t, ok)
}

func TestEncodeDecode(t *testing.T) {
	r := require.New(t)
	rect := quadtree.NewRect(-10, -20, 30, 40)
	points := []quadtree.Point{{X: -7, Y: -6}, {X: -3, Y: -2}, {X: 1, Y: 2}, {X: 5, Y: 6}}

	rectBytes := pcs.EncodeRect(rect)
	decRect := pcs.DecodeRect(rectBytes)
	r.Equal(rect, decRect)

	evmRectBytes := pcs.EvmEncodeRect(rect)
	evmDecRect := pcs.EvmDecodeRect(evmRectBytes)
	r.Equal(rect, evmDecRect)

	evmPointsBytes := pcs.EvmEncodePoints(points)
	evmDecPoints := pcs.EvmDecodePoints(evmPointsBytes)
	r.Len(evmDecPoints, len(points))
	r.Equal(points, evmDecPoints)
}
