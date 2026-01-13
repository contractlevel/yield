// Code generated — DO NOT EDIT.

//go:build !wasip1

package pool_addresses_provider

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

// PoolAddressesProviderMock is a mock implementation of PoolAddressesProvider for testing.
type PoolAddressesProviderMock struct {
	GetMarketId         func(GetMarketIdInput) (string, error)
	GetPool             func() (common.Address, error)
	GetPoolDataProvider func() (common.Address, error)
	Owner               func() (common.Address, error)
}

// NewPoolAddressesProviderMock creates a new PoolAddressesProviderMock for testing.
func NewPoolAddressesProviderMock(address common.Address, clientMock *evmmock.ClientCapability) *PoolAddressesProviderMock {
	mock := &PoolAddressesProviderMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getMarketId"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetMarketId == nil {
				return nil, errors.New("getMarketId method not mocked")
			}
			inputs := abi.Methods["getMarketId"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetMarketIdInput{
				MarketId: values[0].(common.Address),
			}

			result, err := mock.GetMarketId(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getMarketId"].Outputs.Pack(result)
		},
		string(abi.Methods["getPool"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPool == nil {
				return nil, errors.New("getPool method not mocked")
			}
			result, err := mock.GetPool()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPool"].Outputs.Pack(result)
		},
		string(abi.Methods["getPoolDataProvider"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPoolDataProvider == nil {
				return nil, errors.New("getPoolDataProvider method not mocked")
			}
			result, err := mock.GetPoolDataProvider()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPoolDataProvider"].Outputs.Pack(result)
		},
		string(abi.Methods["owner"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Owner == nil {
				return nil, errors.New("owner method not mocked")
			}
			result, err := mock.Owner()
			if err != nil {
				return nil, err
			}
			return abi.Methods["owner"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
