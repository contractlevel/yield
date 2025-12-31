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
	GetACLAdmin            func() (common.Address, error)
	GetACLManager          func() (common.Address, error)
	GetAddress             func(GetAddressInput) (common.Address, error)
	GetMarketId            func() (string, error)
	GetPool                func() (common.Address, error)
	GetPoolConfigurator    func() (common.Address, error)
	GetPoolDataProvider    func() (common.Address, error)
	GetPriceOracle         func() (common.Address, error)
	GetPriceOracleSentinel func() (common.Address, error)
	Owner                  func() (common.Address, error)
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
		string(abi.Methods["getACLAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetACLAdmin == nil {
				return nil, errors.New("getACLAdmin method not mocked")
			}
			result, err := mock.GetACLAdmin()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getACLAdmin"].Outputs.Pack(result)
		},
		string(abi.Methods["getACLManager"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetACLManager == nil {
				return nil, errors.New("getACLManager method not mocked")
			}
			result, err := mock.GetACLManager()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getACLManager"].Outputs.Pack(result)
		},
		string(abi.Methods["getAddress"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAddress == nil {
				return nil, errors.New("getAddress method not mocked")
			}
			inputs := abi.Methods["getAddress"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetAddressInput{
				Id: values[0].([32]byte),
			}

			result, err := mock.GetAddress(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAddress"].Outputs.Pack(result)
		},
		string(abi.Methods["getMarketId"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetMarketId == nil {
				return nil, errors.New("getMarketId method not mocked")
			}
			result, err := mock.GetMarketId()
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
		string(abi.Methods["getPoolConfigurator"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPoolConfigurator == nil {
				return nil, errors.New("getPoolConfigurator method not mocked")
			}
			result, err := mock.GetPoolConfigurator()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPoolConfigurator"].Outputs.Pack(result)
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
		string(abi.Methods["getPriceOracle"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPriceOracle == nil {
				return nil, errors.New("getPriceOracle method not mocked")
			}
			result, err := mock.GetPriceOracle()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPriceOracle"].Outputs.Pack(result)
		},
		string(abi.Methods["getPriceOracleSentinel"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPriceOracleSentinel == nil {
				return nil, errors.New("getPriceOracleSentinel method not mocked")
			}
			result, err := mock.GetPriceOracleSentinel()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPriceOracleSentinel"].Outputs.Pack(result)
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
