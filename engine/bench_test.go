package main

import (
	"concrete-quad/engine/pcs"
	"concrete-quad/engine/pcs/quadtree"
	pcs_test "concrete-quad/engine/pcs/test"
	"fmt"
	"math/rand"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	cc_api "github.com/ethereum/go-ethereum/concrete/api"
	"github.com/ethereum/go-ethereum/concrete/contracts"
	"github.com/ethereum/go-ethereum/concrete/wasm"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/ethdb/memorydb"
)

var implementations = []struct {
	name string
	pc   cc_api.Precompile
	addr common.Address
}{
	{"Native", pcs.QuadDBPrecompile, common.HexToAddress("0x1e510001")},
	{"WASM", wasm.NewWasmPrecompile(quaddbWasm, common.HexToAddress("0x1e510002")), common.HexToAddress("0x1e510002")},
}

func BenchmarkQuadTreeCreate(b *testing.B) {
	for _, impl := range implementations {
		b.Run(impl.name, func(b *testing.B) {
			rect := quadtree.NewRect(0, 0, 100, 100)
			api := pcs_test.NewTestAPI()
			wpc := pcs_test.QuadPCWrapper{Precompile: impl.pc}
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_, err := wpc.Create(api, rect)
				if err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func BenchmarkQuadTreeRead(b *testing.B) {
	for _, impl := range implementations {
		b.Run(impl.name, func(b *testing.B) {
			wpc := pcs_test.QuadPCWrapper{Precompile: impl.pc}
			api := pcs_test.NewTestAPI()
			id, err := wpc.Create(api, quadtree.NewRect(0, 0, 100, 100))
			if err != nil {
				b.Fatal(err)
			}
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_, _, _, err := wpc.Read(api, id)
				if err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func randomPoint(min int, max int) quadtree.Point {
	return quadtree.Point{X: rand.Intn(max-min) + min, Y: rand.Intn(max-min) + min}
}

func BenchmarkQuadTreeAdd(b *testing.B) {
	rand.Seed(1)
	halfSide := 5_000
	treeSizes := []int{0, 100, 1000, 10000}
	for _, impl := range implementations {
		wpc := pcs_test.QuadPCWrapper{Precompile: impl.pc}
		address := impl.addr
		contracts.AddPrecompile(address, pcs.QuadDBPrecompile)
		b.Run(impl.name, func(b *testing.B) {
			for _, size := range treeSizes {
				b.Run(fmt.Sprintf("TreeSize_%d", size), func(b *testing.B) {
					memdb := memorydb.New()
					db := state.NewDatabase(rawdb.NewDatabase(memdb))
					state0, _ := state.New(common.Hash{}, db, nil)
					api0 := pcs_test.NewTestAPIWithStateDB(state0, address)
					state0.SetBalance(address, common.Big1)

					// Set up tree and record memdb length increase
					dbStartLen := memdb.Len()
					id, err := wpc.Create(api0, quadtree.NewRect(-halfSide, -halfSide, 2*halfSide, 2*halfSide))
					if err != nil {
						b.Fatal(err)
					}
					for i := 0; i < size; i++ {
						_, err := wpc.Add(api0, id, randomPoint(-halfSide, halfSide))
						if err != nil {
							b.Fatal(err)
						}
					}
					state0Root, err := state0.Commit(true)
					if err != nil {
						b.Fatal(err)
					}
					dbDeltaPreimages := memdb.Len() - dbStartLen
					err = state0.Database().TrieDB().Commit(state0Root, false)
					if err != nil {
						b.Fatal(err)
					}
					dbDeltaTrieNodes := memdb.Len() - dbStartLen - dbDeltaPreimages

					// Run benchmark
					b.ResetTimer()
					elapsedTime := time.Duration(0)
					oks := 0
					for i := 0; i < b.N; i++ {
						// Reset state
						state1, _ := state.New(state0Root, db, nil)
						api1 := pcs_test.NewTestAPIWithStateDB(state1, address)
						point := randomPoint(-halfSide, halfSide)
						// ==== Start timer ====
						startTime := time.Now()
						// Add point
						ok, err := wpc.Add(api1, id, point)
						if err != nil {
							b.Fatal(err)
						}
						elapsedTime += time.Since(startTime)
						// ====  Stop timer  ====
						if ok {
							oks++
						}
					}
					b.StopTimer()
					b.ReportMetric(float64(elapsedTime.Nanoseconds())/float64(b.N), "ns/op")
					// b.ReportMetric(float64(oks)/float64(b.N), "ok")
					if size > 0 {
						b.ReportMetric(float64(dbDeltaPreimages), "pi-entries")
						b.ReportMetric(float64(dbDeltaTrieNodes), "trie-entries")
					}
				})
			}
		})
	}
}

// TODO: bench searchRect and has
