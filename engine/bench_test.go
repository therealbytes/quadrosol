package main

import (
	"concrete-quad/engine/pcs"
	"concrete-quad/engine/pcs/quadtree"
	pcs_test "concrete-quad/engine/pcs/test"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math"
	"math/big"
	"math/rand"
	"os"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	cc_api "github.com/ethereum/go-ethereum/concrete/api"
	"github.com/ethereum/go-ethereum/concrete/wasm"
	"github.com/ethereum/go-ethereum/core"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/ethereum/go-ethereum/ethdb/memorydb"
	"github.com/ethereum/go-ethereum/params"
)

var implementations = []struct {
	name string
	db   pcs_test.QuadDB
	addr common.Address
}{
	{
		"Native",
		pcs_test.QuadPCWrapper{Precompile: pcs.QuadDBPrecompile},
		common.HexToAddress("0x1e510001"),
	}, {
		"WASM",
		pcs_test.QuadPCWrapper{Precompile: wasm.NewWasmPrecompile(quaddbWasm, common.HexToAddress("0x1e510002"))},
		common.HexToAddress("0x1e510002"),
	}, {
		"Solidity",
		newQuadBytecodeWrapper("../out/QuadTree.sol/QuadTreeMap.json"),
		common.HexToAddress("0x1e510003"),
	},
}

func BenchmarkQuadTreeCreate(b *testing.B) {
	for _, impl := range implementations {
		b.Run(impl.name, func(b *testing.B) {
			rect := quadtree.NewRect(0, 0, 100, 100)
			api := pcs_test.NewTestAPI()
			quaddb := impl.db
			address := impl.addr
			quaddb.Init(api, address)
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_, err := quaddb.Create(api, rect)
				if err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func BenchmarkQuadTreeRead(b *testing.B) {
	for _, impl := range implementations {
		if impl.name == "Solidity" {
			continue
		}
		b.Run(impl.name, func(b *testing.B) {
			api := pcs_test.NewTestAPI()
			quaddb := impl.db
			address := impl.addr
			quaddb.Init(api, address)
			id, err := quaddb.Create(api, quadtree.NewRect(0, 0, 100, 100))
			if err != nil {
				b.Fatal(err)
			}
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_, _, _, err := quaddb.Read(api, id)
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
	treeSizes := []int{0, 100, 1000}
	for _, impl := range implementations {
		quaddb := impl.db
		address := impl.addr
		b.Run(impl.name, func(b *testing.B) {
			for _, size := range treeSizes {
				b.Run(fmt.Sprintf("TreeSize_%d", size), func(b *testing.B) {
					memdb := memorydb.New()
					db := state.NewDatabase(rawdb.NewDatabase(memdb))
					state0, _ := state.New(common.Hash{}, db, nil)
					api0 := pcs_test.NewTestAPIWithStateDB(state0, address)
					quaddb.Init(api0, address)

					// Set up tree and record memdb length increase
					dbStartLen := memdb.Len()
					id, err := quaddb.Create(api0, quadtree.NewRect(-halfSide, -halfSide, 2*halfSide, 2*halfSide))
					if err != nil {
						b.Fatal(err)
					}
					for i := 0; i < size; i++ {
						_, err := quaddb.Add(api0, id, randomPoint(-halfSide, halfSide))
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
						ok, err := quaddb.Add(api1, id, point)
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
					b.ReportMetric(float64(elapsedTime.Microseconds())/float64(b.N), "adj-μs/op")
					// b.ReportMetric(float64(oks)/float64(b.N), "ok")
					b.ReportMetric(float64(dbDeltaPreimages), "sc-len")
					b.ReportMetric(float64(dbDeltaTrieNodes), "tc-len")
				})
			}
		})
	}
}

// TODO: bench searchRect and has

type abiPoint struct {
	X int32
	Y int32
}

type abiRect struct {
	Min abiPoint
	Max abiPoint
}

type quadBytecodeWrapper struct {
	abi      abi.ABI
	bytecode []byte
	address  common.Address
}

func newQuadBytecodeWrapper(abiFile string) *quadBytecodeWrapper {
	w := &quadBytecodeWrapper{}

	// Read file
	file, err := os.Open(abiFile)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	data, err := ioutil.ReadAll(file)
	if err != nil {
		panic(err)
	}

	// Get bytecode
	var bytecode struct {
		DeployedBytecode struct {
			Object string `json:"object"`
		} `json:"deployedBytecode"`
	}
	err = json.Unmarshal(data, &bytecode)
	if err != nil {
		panic(err)
	}
	w.bytecode = common.Hex2Bytes(bytecode.DeployedBytecode.Object[2:])

	// Get ABI
	var jsonAbi struct {
		ABI abi.ABI `json:"abi"`
	}
	err = json.Unmarshal(data, &jsonAbi)
	if err != nil {
		panic(err)
	}
	w.abi = jsonAbi.ABI

	return w
}

func (w *quadBytecodeWrapper) run(api cc_api.API, input []byte) ([]byte, error) {
	statedb := api.StateDB().(*state.StateDB)

	origin := common.HexToAddress("0x111111coffee")
	txContext := vm.TxContext{
		Origin:   origin,
		GasPrice: big.NewInt(1),
	}
	context := vm.BlockContext{
		CanTransfer: core.CanTransfer,
		Transfer:    core.Transfer,
		Coinbase:    common.Address{},
		BlockNumber: new(big.Int).SetUint64(0x01),
		Time:        1,
		Difficulty:  big.NewInt(0x01),
		GasLimit:    uint64(100_000_000),
	}
	evm := vm.NewEVM(context, txContext, statedb, params.TestChainConfig, vm.Config{})

	ret, _, err := evm.Call(vm.AccountRef(origin), w.address, input, math.MaxUint64, common.Big0)

	if err != nil {
		return nil, err
	}
	return ret, nil
}

func (w *quadBytecodeWrapper) Init(api cc_api.API, address common.Address) error {
	w.address = address
	statedb := api.StateDB().(*state.StateDB)
	statedb.CreateAccount(address)
	statedb.SetCode(address, w.bytecode)
	statedb.Finalise(true)
	return statedb.Error()
}

func (w *quadBytecodeWrapper) Create(api cc_api.API, rect quadtree.Rect) (int, error) {
	_rect := &abiRect{
		Min: abiPoint{
			X: int32(rect.Min.X),
			Y: int32(rect.Min.Y),
		},
		Max: abiPoint{
			X: int32(rect.Max.X),
			Y: int32(rect.Max.Y),
		},
	}
	input, err := w.abi.Pack("create", _rect)
	if err != nil {
		return -1, err
	}
	output, err := w.run(api, input)
	if err != nil {
		return -1, err
	}
	values, err := w.abi.Unpack("create", output)
	if err != nil {
		return -1, err
	}
	id := values[0].(*big.Int)
	return int(id.Int64()), nil
}

func (w *quadBytecodeWrapper) Read(api cc_api.API, id int) (common.Hash, int, quadtree.Rect, error) {
	panic("not implemented")
}

func (w *quadBytecodeWrapper) Add(api cc_api.API, id int, point quadtree.Point) (bool, error) {
	_id := big.NewInt(int64(id))
	_point := &abiPoint{
		X: int32(point.X),
		Y: int32(point.Y),
	}
	input, err := w.abi.Pack("add", _id, _point)
	if err != nil {
		return false, err
	}
	output, err := w.run(api, input)
	if err != nil {
		return false, err
	}
	values, err := w.abi.Unpack("add", output)
	if err != nil {
		return false, err
	}
	return values[0].(bool), nil
}

func (w *quadBytecodeWrapper) Has(api cc_api.API, id int, point quadtree.Point) (bool, error) {
	_id := big.NewInt(int64(id))
	_point := &abiPoint{
		X: int32(point.X),
		Y: int32(point.Y),
	}
	input, err := w.abi.Pack("has", _id, _point)
	if err != nil {
		return false, err
	}
	output, err := w.run(api, input)
	if err != nil {
		return false, err
	}
	values, err := w.abi.Unpack("has", output)
	if err != nil {
		return false, err
	}
	return values[0].(bool), nil
}

func (w *quadBytecodeWrapper) SearchRect(api cc_api.API, id int, rect quadtree.Rect) ([]quadtree.Point, error) {
	panic("not implemented")
}

var _ pcs_test.QuadDB = &quadBytecodeWrapper{}

func TestQuadBytecodeWrapper(t *testing.T) {
	address := common.HexToAddress("0x1e510003")
	quaddb := newQuadBytecodeWrapper("../out/QuadTree.sol/QuadTreeMap.json")
	api := pcs_test.NewTestAPI()
	err := quaddb.Init(api, address)
	if err != nil {
		t.Fatal(err)
	}
	id, err := quaddb.Create(api, quadtree.NewRect(0, 0, 100, 100))
	if err != nil {
		t.Fatal(err)
	}
	_, err = quaddb.Add(api, id, quadtree.Point{X: 50, Y: 50})
	if err != nil {
		t.Fatal(err)
	}
	ok, err := quaddb.Has(api, id, quadtree.Point{X: 50, Y: 50})
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("expected has() to return true")
	}
	ok, err = quaddb.Has(api, id, quadtree.Point{X: 51, Y: 50})
	if err != nil {
		t.Fatal(err)
	}
	if ok {
		t.Fatal("expected has() to return false")
	}
}
