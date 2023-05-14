package main

import (
	"testing"

	"github.com/ethereum/go-ethereum/concrete"
)

func TestSetup(t *testing.T) {
	engine := concrete.ConcreteGeth
	setup(engine)
}
