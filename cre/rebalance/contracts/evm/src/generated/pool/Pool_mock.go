// Code generated — DO NOT EDIT.

//go:build !wasip1

package pool

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

// PoolMock is a mock implementation of Pool for testing.
type PoolMock struct {
	GetReserveData func(GetReserveDataInput) (GetReserveDataOutput, error)
}

// NewPoolMock creates a new PoolMock for testing.
func NewPoolMock(address common.Address, clientMock *evmmock.ClientCapability) *PoolMock {
	mock := &PoolMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getReserveData"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetReserveData == nil {
				return nil, errors.New("getReserveData method not mocked")
			}
			inputs := abi.Methods["getReserveData"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetReserveDataInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetReserveData(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getReserveData"].Outputs.Pack(
				result.Configuration,
				result.LiquidityIndex,
				result.CurrentLiquidityRate,
				result.VariableBorrowIndex,
				result.CurrentVariableBorrowRate,
				result.CurrentStableBorrowRate,
				result.LastUpdateTimestamp,
				result.ATokenAddress,
				result.StableDebtTokenAddress,
				result.VariableDebtTokenAddress,
				result.InterestRateStrategyAddress,
				result.AccruedToTreasury,
				result.Unbacked,
				result.IsolationModeTotalDebt,
			)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
