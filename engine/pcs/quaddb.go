package pcs

import (
	"bytes"
	"fmt"
	"math/big"

	"github.com/therealbytes/quadrosol/engine/pcs/quadtree"

	"github.com/ethereum/go-ethereum/common"
	cc_api "github.com/ethereum/go-ethereum/concrete/api"
	"github.com/ethereum/go-ethereum/concrete/lib"
	tg_lib "github.com/ethereum/go-ethereum/tinygo/std"
)

const (
	Op_QuadDB_Create = iota
	Op_QuadDB_Delete
	Op_QuadDB_Duplicate
	Op_QuadDB_Read
	Op_QuadDB_Add
	Op_QuadDB_Remove
	Op_QuadDB_Replace
	Op_QuadDB_Has
	Op_QuadDB_KNearest
	Op_QuadDB_SearchRect
	Op_QuadDB_SearchCircle
)

type quadCoreDB struct {
	cc_api.API
}

func NewQuadCoreDB(api cc_api.API) *quadCoreDB {
	return &quadCoreDB{api}
}

func (db *quadCoreDB) Get(key common.Hash) (*quadtree.QuadTreeCore, error) {
	statedb := db.StateDB()
	blob := statedb.GetEphemeralPreimage(key)
	if len(blob) == 0 {
		blob = statedb.GetPersistentPreimage(key)
		if len(blob) == 0 {
			return nil, fmt.Errorf("not found")
		}
	}
	core := &quadtree.QuadTreeCore{}
	core.Decode(blob)
	return core, nil
}

func (db *quadCoreDB) Put(qt *quadtree.QuadTreeCore) (common.Hash, error) {
	hash := qt.Hash()
	db.StateDB().AddEphemeralPreimage(hash, qt.Encode())
	return hash, nil
}

func (db *quadCoreDB) getEphemeral(key common.Hash) (*quadtree.QuadTreeCore, bool) {
	blob := db.StateDB().GetEphemeralPreimage(key)
	if len(blob) == 0 {
		return nil, false
	}
	core := &quadtree.QuadTreeCore{}
	core.Decode(blob)
	return core, true
}

var (
	RootCounterID    = tg_lib.Keccak256Hash([]byte("quad.RootCounter.v0"))
	RootMapID        = tg_lib.Keccak256Hash([]byte("quad.RootMap.v0"))
	MetadataMapID    = tg_lib.Keccak256Hash([]byte("quad.MetadataMap.v0"))
	DirtiesTrackerID = tg_lib.Keccak256Hash([]byte("quad.DirtiesTracker.v0"))
)

type quadRecordDB struct {
	cc_api.API
	_roots    cc_api.Mapping
	_metadata cc_api.Mapping
	_dirties  DirtiesTracker
	_counter  *lib.Counter
}

func NewQuadRecordDB(api cc_api.API) *quadRecordDB {
	return &quadRecordDB{API: api}
}

func (db *quadRecordDB) roots() cc_api.Mapping {
	if db._roots == nil {
		db._roots = db.Persistent().NewMap(RootMapID)
	}
	return db._roots
}

func (db *quadRecordDB) metadata() cc_api.Mapping {
	if db._metadata == nil {
		db._metadata = db.Persistent().NewMap(MetadataMapID)
	}
	return db._metadata
}

func (db *quadRecordDB) dirties() DirtiesTracker {
	if db._dirties.m == nil {
		db._dirties = NewDirtyTracker(db.Ephemeral(), DirtiesTrackerID)
	}
	return db._dirties
}

func (db *quadRecordDB) counter() *lib.Counter {
	if db._counter == nil {
		db._counter = lib.NewCounter(db.Persistent().NewReference(RootCounterID))
	}
	return db._counter
}

func (db *quadRecordDB) AddRoot(rect quadtree.Rect) *big.Int {
	counter := db.counter()
	id := counter.Get()
	counter.Inc()
	db.metadata().Set(common.BigToHash(id), encodeRootMetadata(0, rect))
	return id
}

func (db *quadRecordDB) DeleteRoot(id *big.Int) {
	counter := db.counter()
	if counter.Get().Cmp(new(big.Int).Add(id, common.Big1)) == 0 {
		// Counter == ID + 1 implies this is the most recent root
		counter.Reference.Set(common.BigToHash(id))
	}
	rootHash := db.roots().Get(common.BigToHash(id))
	db.dirties().Dec(rootHash)
	db.roots().Set(common.BigToHash(id), common.Hash{})
	db.metadata().Set(common.BigToHash(id), common.Hash{})
}

func (db *quadRecordDB) SetRootHash(id *big.Int, hash common.Hash) {
	rootHash := db.roots().Get(common.BigToHash(id))
	db.dirties().Dec(rootHash)
	db.dirties().Inc(hash)
	db.roots().Set(common.BigToHash(id), hash)
}

func (db *quadRecordDB) SetRootSize(id *big.Int, size int) {
	metadata := db.metadata()
	data := metadata.Get(common.BigToHash(id))
	_, rect := decodeRootMetadata(data)
	metadata.Set(common.BigToHash(id), encodeRootMetadata(size, rect))
}

func (db *quadRecordDB) GetRootData(id *big.Int) (common.Hash, int, quadtree.Rect) {
	rootHash := db.roots().Get(common.BigToHash(id))
	data := db.metadata().Get(common.BigToHash(id))
	size, rect := decodeRootMetadata(data)
	return rootHash, size, rect
}

func (db *quadRecordDB) DirtyRoots() cc_api.Array {
	return db.dirties().Dirties()
}

func encodeRootMetadata(size int, rect quadtree.Rect) common.Hash {
	data := make([]byte, 32)
	copy(data[12:16], quadtree.Int32ToBytes(int32(size)))
	copy(data[16:32], EncodeRect(rect))
	return common.BytesToHash(data)
}

func decodeRootMetadata(data common.Hash) (int, quadtree.Rect) {
	size := int(quadtree.BytesToInt32(data[12:16]))
	rect := DecodeRect(data[16:32])
	return size, rect
}

var QuadDBPrecompile = lib.PrecompileDemux{
	Op_QuadDB_Create:     &CreateQuadTree{},
	Op_QuadDB_Read:       &ReadQuadTree{},
	Op_QuadDB_Add:        &AddToQuadTree{},
	Op_QuadDB_Has:        &QuadTreeHas{},
	Op_QuadDB_SearchRect: &QuadTreeSearchRect{},
}

var (
	EvmPointSize  uint64 = 64
	EvmRectSize   uint64 = 128
	EvmCircleSize uint64 = 96
	EvmIntSize    uint64 = 32
	EvmBoolSize   uint64 = 32
)

var (
	FalseBytes = EvmEncodeInt(0)
	TrueBytes  = EvmEncodeInt(1)
)

type CreateQuadTree struct {
	lib.BlankPrecompile
}

func (pc *CreateQuadTree) MutatesStorage(input []byte) bool {
	return true
}

func (pc *CreateQuadTree) Run(api cc_api.API, input []byte) ([]byte, error) {
	coredb := NewQuadCoreDB(api)
	recorddb := NewQuadRecordDB(api)
	rect := EvmDecodeRect(lib.GetData(input, 0, EvmRectSize))
	id := recorddb.AddRoot(rect)
	qt := quadtree.NewEmptyQuadTreeMerkle(rect, coredb)
	hash := quadtree.AddQuadTreeMerkle(qt, coredb)
	recorddb.SetRootHash(id, hash)
	return common.BigToHash(id).Bytes(), nil
}

type ReadQuadTree struct {
	lib.BlankPrecompile
}

func (pc *ReadQuadTree) MutatesStorage(input []byte) bool {
	return false
}

func (pc *ReadQuadTree) Run(api cc_api.API, input []byte) ([]byte, error) {
	recorddb := NewQuadRecordDB(api)
	id := new(big.Int).SetBytes(lib.GetData(input, 0, EvmIntSize))
	hash, size, rect := recorddb.GetRootData(id)
	return bytes.Join([][]byte{hash.Bytes(), EvmEncodeInt(size), EvmEncodeRect(rect)}, []byte{}), nil
}

type AddToQuadTree struct {
	lib.BlankPrecompile
	committedHashes map[common.Hash]struct{}
}

func (pc *AddToQuadTree) MutatesStorage(input []byte) bool {
	return true
}

func (pc *AddToQuadTree) Commit(api cc_api.API) error {
	coredb := NewQuadCoreDB(api)
	statedb := api.StateDB()
	dirties := NewQuadRecordDB(api).DirtyRoots()
	pc.committedHashes = make(map[common.Hash]struct{})
	for i := 0; i < dirties.Length(); i++ {
		hash := dirties.Get(i)
		pc.commitQuadTree(coredb, statedb, hash)
	}
	pc.committedHashes = nil
	return nil
}

func (pc *AddToQuadTree) commitQuadTree(coredb *quadCoreDB, statedb cc_api.StateDB, hash common.Hash) {
	if _, ok := pc.committedHashes[hash]; ok {
		return
	}
	core, ok := coredb.getEphemeral(hash)
	if !ok {
		return
	}
	if len(pc.committedHashes) < 1000 {
		// Quick fix: tinygo behaves unexpectedly when the map is large
		pc.committedHashes[hash] = struct{}{}
	}
	statedb.AddPersistentPreimage(hash, core.Encode())
	for _, childHash := range core.QuadHashes() {
		pc.commitQuadTree(coredb, statedb, childHash)
	}
}

func (pc *AddToQuadTree) Run(api cc_api.API, input []byte) ([]byte, error) {
	coredb := NewQuadCoreDB(api)
	recorddb := NewQuadRecordDB(api)
	id := new(big.Int).SetBytes(lib.GetData(input, 0, EvmIntSize))
	point := EvmDecodePoint(lib.GetData(input, EvmIntSize, EvmPointSize))
	hash, size, rect := recorddb.GetRootData(id)
	if !rect.Contains(point) {
		return FalseBytes, nil
	}
	qt := quadtree.GetQuadTreeMerkle(hash, rect, coredb)
	newQt, ok := qt.Insert(point)
	if !ok {
		return FalseBytes, nil
	}
	recorddb.SetRootHash(id, newQt.Hash())
	recorddb.SetRootSize(id, size+1)
	return TrueBytes, nil
}

type QuadTreeHas struct {
	lib.BlankPrecompile
}

func (pc *QuadTreeHas) MutatesStorage(input []byte) bool {
	return false
}

func (pc *QuadTreeHas) Run(api cc_api.API, input []byte) ([]byte, error) {
	coredb := NewQuadCoreDB(api)
	recorddb := NewQuadRecordDB(api)
	id := new(big.Int).SetBytes(lib.GetData(input, 0, EvmIntSize))
	point := EvmDecodePoint(lib.GetData(input, EvmIntSize, EvmPointSize))
	hash, size, rect := recorddb.GetRootData(id)
	if size == 0 || !rect.Contains(point) {
		return FalseBytes, nil
	}
	qt := quadtree.GetQuadTreeMerkle(hash, rect, coredb)
	if qt.Contains(point) {
		return TrueBytes, nil
	} else {
		return FalseBytes, nil
	}
}

type QuadTreeSearchRect struct {
	lib.BlankPrecompile
}

func (pc *QuadTreeSearchRect) MutatesStorage(input []byte) bool {
	return false
}

func (pc *QuadTreeSearchRect) Run(api cc_api.API, input []byte) ([]byte, error) {
	coredb := NewQuadCoreDB(api)
	recorddb := NewQuadRecordDB(api)
	id := new(big.Int).SetBytes(lib.GetData(input, 0, EvmIntSize))
	queryRect := EvmDecodeRect(lib.GetData(input, EvmIntSize, EvmRectSize))
	hash, size, rect := recorddb.GetRootData(id)
	if size == 0 || !rect.IntersectsRect(queryRect) {
		return EvmEncodePoints(nil), nil
	}
	qt := quadtree.GetQuadTreeMerkle(hash, rect, coredb)
	wqt := quadtree.NewQuadTreeMerkleWrap(qt)
	points := quadtree.SearchRect(wqt, queryRect)
	return EvmEncodePoints(points), nil
}
