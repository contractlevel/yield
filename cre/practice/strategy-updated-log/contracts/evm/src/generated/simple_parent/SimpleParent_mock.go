// Code generated — DO NOT EDIT.

//go:build !wasip1

package simple_parent

import (
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	evmmock "github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/mock"
)

var (
	_ = errors.New
	_ = fmt.Errorf
	_ = big.NewInt
	_ = common.Big1
)

// SimpleParentMock is a mock implementation of SimpleParent for testing.
type SimpleParentMock struct {
	GetStrategy func() (Strategy, error)
}

// NewSimpleParentMock creates a new SimpleParentMock for testing.
func NewSimpleParentMock(address common.Address, clientMock *evmmock.ClientCapability) *SimpleParentMock {
	mock := &SimpleParentMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getStrategy"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetStrategy == nil {
				return nil, errors.New("getStrategy method not mocked")
			}
			result, err := mock.GetStrategy()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getStrategy"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
