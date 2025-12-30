// Code generated — DO NOT EDIT.

//go:build !wasip1

package strategy_helper

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

// StrategyHelperMock is a mock implementation of StrategyHelper for testing.
type StrategyHelperMock struct {
	GetAaveAPR               func(GetAaveAPRInput) (*big.Int, error)
	GetPoolAddressesProvider func() (common.Address, error)
}

// NewStrategyHelperMock creates a new StrategyHelperMock for testing.
func NewStrategyHelperMock(address common.Address, clientMock *evmmock.ClientCapability) *StrategyHelperMock {
	mock := &StrategyHelperMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getAaveAPR"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAaveAPR == nil {
				return nil, errors.New("getAaveAPR method not mocked")
			}
			inputs := abi.Methods["getAaveAPR"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := GetAaveAPRInput{
				LiquidityAdded: values[0].(*big.Int),
				Asset:          values[1].(common.Address),
			}

			result, err := mock.GetAaveAPR(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAaveAPR"].Outputs.Pack(result)
		},
		string(abi.Methods["getPoolAddressesProvider"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPoolAddressesProvider == nil {
				return nil, errors.New("getPoolAddressesProvider method not mocked")
			}
			result, err := mock.GetPoolAddressesProvider()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPoolAddressesProvider"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
