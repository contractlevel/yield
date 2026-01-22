// Code generated — DO NOT EDIT.

//go:build !wasip1

package comet

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

// CometMock is a mock implementation of Comet for testing.
type CometMock struct {
	GetSupplyRate func(GetSupplyRateInput) (uint64, error)
	TotalBorrow   func() (*big.Int, error)
	TotalSupply   func() (*big.Int, error)
}

// NewCometMock creates a new CometMock for testing.
func NewCometMock(address common.Address, clientMock *evmmock.ClientCapability) *CometMock {
	mock := &CometMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getSupplyRate"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetSupplyRate == nil {
				return nil, errors.New("getSupplyRate method not mocked")
			}
			inputs := abi.Methods["getSupplyRate"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetSupplyRateInput{
				Utilization: values[0].(*big.Int),
			}

			result, err := mock.GetSupplyRate(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getSupplyRate"].Outputs.Pack(result)
		},
		string(abi.Methods["totalBorrow"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.TotalBorrow == nil {
				return nil, errors.New("totalBorrow method not mocked")
			}
			result, err := mock.TotalBorrow()
			if err != nil {
				return nil, err
			}
			return abi.Methods["totalBorrow"].Outputs.Pack(result)
		},
		string(abi.Methods["totalSupply"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.TotalSupply == nil {
				return nil, errors.New("totalSupply method not mocked")
			}
			result, err := mock.TotalSupply()
			if err != nil {
				return nil, err
			}
			return abi.Methods["totalSupply"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
