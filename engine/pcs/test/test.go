package test

import (
	"bytes"
	"concrete-quad/engine/pcs"
	"concrete-quad/engine/pcs/quadtree"

	"github.com/ethereum/go-ethereum/common"
	cc_api "github.com/ethereum/go-ethereum/concrete/api"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/ethereum/go-ethereum/params"
)

// NOTE: Concrete should export this

func NewTestAPI() cc_api.API {
	db := state.NewDatabase(rawdb.NewMemoryDatabase())
	statedb, _ := state.New(common.Hash{}, db, nil)
	addr := common.HexToAddress("0xc0ffee")
	return NewTestAPIWithStateDB(statedb, addr)
}

func NewTestAPIWithStateDB(statedb vm.StateDB, addr common.Address) cc_api.API {
	evm := vm.NewEVM(vm.BlockContext{}, vm.TxContext{}, statedb, params.TestChainConfig, vm.Config{})
	return cc_api.New(evm.NewConcreteEVM(), addr)
}

type QuadPCWrapper struct {
	cc_api.Precompile
}

func (w QuadPCWrapper) run(api cc_api.API, opcode int, input []byte) ([]byte, error) {
	return w.Run(api, bytes.Join([][]byte{pcs.EvmEncodeInt(opcode), input}, []byte{}))
}

func (w QuadPCWrapper) Create(api cc_api.API, rect quadtree.Rect) (int, error) {
	input := pcs.EvmEncodeRect(rect)
	output, err := w.run(api, pcs.Op_QuadDB_Create, input)
	if err != nil {
		return -1, err
	}
	return pcs.EvmDecodeInt(output), nil
}

func (w QuadPCWrapper) Read(api cc_api.API, id int) (common.Hash, int, quadtree.Rect, error) {
	input := pcs.EvmEncodeInt(id)
	output, err := w.run(api, pcs.Op_QuadDB_Read, input)
	if err != nil {
		return common.Hash{}, -1, quadtree.Rect{}, err
	}
	hash := common.BytesToHash(output[:32])
	count := pcs.EvmDecodeInt(output[32:64])
	rect := pcs.EvmDecodeRect(output[64:])
	return hash, count, rect, nil
}

func (w QuadPCWrapper) Add(api cc_api.API, id int, point quadtree.Point) (bool, error) {
	input := bytes.Join([][]byte{pcs.EvmEncodeInt(id), pcs.EvmEncodePoint(point)}, []byte{})
	output, err := w.run(api, pcs.Op_QuadDB_Add, input)
	if err != nil {
		return false, err
	}
	return pcs.EvmDecodeInt(output) == 1, nil
}

func (w QuadPCWrapper) Has(api cc_api.API, id int, point quadtree.Point) (bool, error) {
	input := bytes.Join([][]byte{pcs.EvmEncodeInt(id), pcs.EvmEncodePoint(point)}, []byte{})
	output, err := w.run(api, pcs.Op_QuadDB_Has, input)
	if err != nil {
		return false, err
	}
	return pcs.EvmDecodeInt(output) == 1, nil
}

func (w QuadPCWrapper) SearchRect(api cc_api.API, id int, rect quadtree.Rect) ([]quadtree.Point, error) {
	input := bytes.Join([][]byte{pcs.EvmEncodeInt(id), pcs.EvmEncodeRect(rect)}, []byte{})
	output, err := w.run(api, pcs.Op_QuadDB_SearchRect, input)
	if err != nil {
		return nil, err
	}
	return pcs.EvmDecodePoints(output), nil
}
