package main

import (
	"concrete-quad/engine/pcs"

	"github.com/ethereum/go-ethereum/tinygo"
)

func init() {
	tinygo.WasmWrap(pcs.QuadDBPrecompile)
}

// main is REQUIRED for TinyGo to compile to Wasm
func main() {}
