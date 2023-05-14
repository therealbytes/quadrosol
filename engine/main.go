package main

import (
	"concrete-quad/engine/pcs"
	_ "embed"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/concrete"
)

//go:embed bin/quaddb.wasm
var quaddbWasm []byte

func setup(engine concrete.ConcreteApp) {
	engine.AddPrecompile(common.HexToAddress("0x80"), pcs.QuadDBPrecompile)
	engine.AddPrecompileWasm(common.HexToAddress("0x81"), quaddbWasm)
}

func main() {
	engine := concrete.ConcreteGeth
	setup(engine)
	engine.Run()
}
