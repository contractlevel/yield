// Code generated — DO NOT EDIT.

//go:build !wasip1

package default_reserve_interest_rate_strategy_v2

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

// DefaultReserveInterestRateStrategyV2Mock is a mock implementation of DefaultReserveInterestRateStrategyV2 for testing.
type DefaultReserveInterestRateStrategyV2Mock struct {
	ADDRESSESPROVIDER         func() (common.Address, error)
	MAXBORROWRATE             func() (*big.Int, error)
	MAXOPTIMALPOINT           func() (*big.Int, error)
	MINOPTIMALPOINT           func() (*big.Int, error)
	CalculateInterestRates    func(CalculateInterestRatesInput) (CalculateInterestRatesOutput, error)
	GetBaseVariableBorrowRate func(GetBaseVariableBorrowRateInput) (*big.Int, error)
	GetInterestRateData       func(GetInterestRateDataInput) (IDefaultInterestRateStrategyV2InterestRateDataRay, error)
	GetInterestRateDataBps    func(GetInterestRateDataBpsInput) (IDefaultInterestRateStrategyV2InterestRateData, error)
	GetMaxVariableBorrowRate  func(GetMaxVariableBorrowRateInput) (*big.Int, error)
	GetOptimalUsageRatio      func(GetOptimalUsageRatioInput) (*big.Int, error)
	GetVariableRateSlope1     func(GetVariableRateSlope1Input) (*big.Int, error)
	GetVariableRateSlope2     func(GetVariableRateSlope2Input) (*big.Int, error)
}

// NewDefaultReserveInterestRateStrategyV2Mock creates a new DefaultReserveInterestRateStrategyV2Mock for testing.
func NewDefaultReserveInterestRateStrategyV2Mock(address common.Address, clientMock *evmmock.ClientCapability) *DefaultReserveInterestRateStrategyV2Mock {
	mock := &DefaultReserveInterestRateStrategyV2Mock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["ADDRESSES_PROVIDER"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.ADDRESSESPROVIDER == nil {
				return nil, errors.New("ADDRESSES_PROVIDER method not mocked")
			}
			result, err := mock.ADDRESSESPROVIDER()
			if err != nil {
				return nil, err
			}
			return abi.Methods["ADDRESSES_PROVIDER"].Outputs.Pack(result)
		},
		string(abi.Methods["MAX_BORROW_RATE"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.MAXBORROWRATE == nil {
				return nil, errors.New("MAX_BORROW_RATE method not mocked")
			}
			result, err := mock.MAXBORROWRATE()
			if err != nil {
				return nil, err
			}
			return abi.Methods["MAX_BORROW_RATE"].Outputs.Pack(result)
		},
		string(abi.Methods["MAX_OPTIMAL_POINT"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.MAXOPTIMALPOINT == nil {
				return nil, errors.New("MAX_OPTIMAL_POINT method not mocked")
			}
			result, err := mock.MAXOPTIMALPOINT()
			if err != nil {
				return nil, err
			}
			return abi.Methods["MAX_OPTIMAL_POINT"].Outputs.Pack(result)
		},
		string(abi.Methods["MIN_OPTIMAL_POINT"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.MINOPTIMALPOINT == nil {
				return nil, errors.New("MIN_OPTIMAL_POINT method not mocked")
			}
			result, err := mock.MINOPTIMALPOINT()
			if err != nil {
				return nil, err
			}
			return abi.Methods["MIN_OPTIMAL_POINT"].Outputs.Pack(result)
		},
		string(abi.Methods["calculateInterestRates"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.CalculateInterestRates == nil {
				return nil, errors.New("calculateInterestRates method not mocked")
			}
			inputs := abi.Methods["calculateInterestRates"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := CalculateInterestRatesInput{
				Params: values[0].(DataTypesCalculateInterestRatesParams),
			}

			result, err := mock.CalculateInterestRates(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["calculateInterestRates"].Outputs.Pack(
				result.Arg0,
				result.Arg1,
			)
		},
		string(abi.Methods["getBaseVariableBorrowRate"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetBaseVariableBorrowRate == nil {
				return nil, errors.New("getBaseVariableBorrowRate method not mocked")
			}
			inputs := abi.Methods["getBaseVariableBorrowRate"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetBaseVariableBorrowRateInput{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetBaseVariableBorrowRate(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getBaseVariableBorrowRate"].Outputs.Pack(result)
		},
		string(abi.Methods["getInterestRateData"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetInterestRateData == nil {
				return nil, errors.New("getInterestRateData method not mocked")
			}
			inputs := abi.Methods["getInterestRateData"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetInterestRateDataInput{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetInterestRateData(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getInterestRateData"].Outputs.Pack(result)
		},
		string(abi.Methods["getInterestRateDataBps"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetInterestRateDataBps == nil {
				return nil, errors.New("getInterestRateDataBps method not mocked")
			}
			inputs := abi.Methods["getInterestRateDataBps"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetInterestRateDataBpsInput{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetInterestRateDataBps(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getInterestRateDataBps"].Outputs.Pack(result)
		},
		string(abi.Methods["getMaxVariableBorrowRate"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetMaxVariableBorrowRate == nil {
				return nil, errors.New("getMaxVariableBorrowRate method not mocked")
			}
			inputs := abi.Methods["getMaxVariableBorrowRate"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetMaxVariableBorrowRateInput{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetMaxVariableBorrowRate(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getMaxVariableBorrowRate"].Outputs.Pack(result)
		},
		string(abi.Methods["getOptimalUsageRatio"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetOptimalUsageRatio == nil {
				return nil, errors.New("getOptimalUsageRatio method not mocked")
			}
			inputs := abi.Methods["getOptimalUsageRatio"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetOptimalUsageRatioInput{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetOptimalUsageRatio(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getOptimalUsageRatio"].Outputs.Pack(result)
		},
		string(abi.Methods["getVariableRateSlope1"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetVariableRateSlope1 == nil {
				return nil, errors.New("getVariableRateSlope1 method not mocked")
			}
			inputs := abi.Methods["getVariableRateSlope1"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetVariableRateSlope1Input{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetVariableRateSlope1(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getVariableRateSlope1"].Outputs.Pack(result)
		},
		string(abi.Methods["getVariableRateSlope2"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetVariableRateSlope2 == nil {
				return nil, errors.New("getVariableRateSlope2 method not mocked")
			}
			inputs := abi.Methods["getVariableRateSlope2"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetVariableRateSlope2Input{
				Reserve: values[0].(common.Address),
			}

			result, err := mock.GetVariableRateSlope2(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getVariableRateSlope2"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
