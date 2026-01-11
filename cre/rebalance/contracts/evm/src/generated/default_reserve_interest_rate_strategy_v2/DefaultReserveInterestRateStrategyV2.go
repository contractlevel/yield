// Code generated — DO NOT EDIT.

package default_reserve_interest_rate_strategy_v2

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"reflect"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
	"github.com/ethereum/go-ethereum/rpc"
	"google.golang.org/protobuf/types/known/emptypb"

	pb2 "github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/chainlink-protos/cre/go/values/pb"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/bindings"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

var (
	_ = bytes.Equal
	_ = errors.New
	_ = fmt.Sprintf
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
	_ = emptypb.Empty{}
	_ = pb.NewBigIntFromInt
	_ = pb2.AggregationType_AGGREGATION_TYPE_COMMON_PREFIX
	_ = bindings.FilterOptions{}
	_ = evm.FilterLogTriggerRequest{}
	_ = cre.ResponseBufferTooSmall
	_ = rpc.API{}
	_ = json.Unmarshal
	_ = reflect.Bool
)

var DefaultReserveInterestRateStrategyV2MetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"provider\",\"type\":\"address\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"optimalUsageRatio\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"baseVariableBorrowRate\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"variableRateSlope1\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"variableRateSlope2\",\"type\":\"uint256\"}],\"name\":\"RateDataUpdate\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"ADDRESSES_PROVIDER\",\"outputs\":[{\"internalType\":\"contractIPoolAddressesProvider\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MAX_BORROW_RATE\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MAX_OPTIMAL_POINT\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MIN_OPTIMAL_POINT\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"unbacked\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidityAdded\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidityTaken\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"totalDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"reserveFactor\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"},{\"internalType\":\"bool\",\"name\":\"usingVirtualBalance\",\"type\":\"bool\"},{\"internalType\":\"uint256\",\"name\":\"virtualUnderlyingBalance\",\"type\":\"uint256\"}],\"internalType\":\"structDataTypes.CalculateInterestRatesParams\",\"name\":\"params\",\"type\":\"tuple\"}],\"name\":\"calculateInterestRates\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getBaseVariableBorrowRate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getInterestRateData\",\"outputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"optimalUsageRatio\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"baseVariableBorrowRate\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"variableRateSlope1\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"variableRateSlope2\",\"type\":\"uint256\"}],\"internalType\":\"structIDefaultInterestRateStrategyV2.InterestRateDataRay\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getInterestRateDataBps\",\"outputs\":[{\"components\":[{\"internalType\":\"uint16\",\"name\":\"optimalUsageRatio\",\"type\":\"uint16\"},{\"internalType\":\"uint32\",\"name\":\"baseVariableBorrowRate\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"variableRateSlope1\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"variableRateSlope2\",\"type\":\"uint32\"}],\"internalType\":\"structIDefaultInterestRateStrategyV2.InterestRateData\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getMaxVariableBorrowRate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getOptimalUsageRatio\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getVariableRateSlope1\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"}],\"name\":\"getVariableRateSlope2\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"},{\"internalType\":\"bytes\",\"name\":\"rateData\",\"type\":\"bytes\"}],\"name\":\"setInterestRateParams\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"reserve\",\"type\":\"address\"},{\"components\":[{\"internalType\":\"uint16\",\"name\":\"optimalUsageRatio\",\"type\":\"uint16\"},{\"internalType\":\"uint32\",\"name\":\"baseVariableBorrowRate\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"variableRateSlope1\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"variableRateSlope2\",\"type\":\"uint32\"}],\"internalType\":\"structIDefaultInterestRateStrategyV2.InterestRateData\",\"name\":\"rateData\",\"type\":\"tuple\"}],\"name\":\"setInterestRateParams\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// Structs
type DataTypesCalculateInterestRatesParams struct {
	Unbacked                 *big.Int
	LiquidityAdded           *big.Int
	LiquidityTaken           *big.Int
	TotalDebt                *big.Int
	ReserveFactor            *big.Int
	Reserve                  common.Address
	UsingVirtualBalance      bool
	VirtualUnderlyingBalance *big.Int
}

type IDefaultInterestRateStrategyV2InterestRateData struct {
	OptimalUsageRatio      uint16
	BaseVariableBorrowRate uint32
	VariableRateSlope1     uint32
	VariableRateSlope2     uint32
}

type IDefaultInterestRateStrategyV2InterestRateDataRay struct {
	OptimalUsageRatio      *big.Int
	BaseVariableBorrowRate *big.Int
	VariableRateSlope1     *big.Int
	VariableRateSlope2     *big.Int
}

// Contract Method Inputs
type CalculateInterestRatesInput struct {
	Params DataTypesCalculateInterestRatesParams
}

type GetBaseVariableBorrowRateInput struct {
	Reserve common.Address
}

type GetInterestRateDataInput struct {
	Reserve common.Address
}

type GetInterestRateDataBpsInput struct {
	Reserve common.Address
}

type GetMaxVariableBorrowRateInput struct {
	Reserve common.Address
}

type GetOptimalUsageRatioInput struct {
	Reserve common.Address
}

type GetVariableRateSlope1Input struct {
	Reserve common.Address
}

type GetVariableRateSlope2Input struct {
	Reserve common.Address
}

type SetInterestRateParamsInput struct {
	Reserve  common.Address
	RateData []byte
}

type SetInterestRateParams0Input struct {
	Reserve  common.Address
	RateData IDefaultInterestRateStrategyV2InterestRateData
}

// Contract Method Outputs
type CalculateInterestRatesOutput struct {
	Arg0 *big.Int
	Arg1 *big.Int
}

// Errors

// Events
// The <Event>Topics struct should be used as a filter (for log triggers).
// Note: It is only possible to filter on indexed fields.
// Indexed (string and bytes) fields will be of type common.Hash.
// They need to he (crypto.Keccak256) hashed and passed in.
// Indexed (tuple/slice/array) fields can be passed in as is, the Encode<Event>Topics function will handle the hashing.
//
// The <Event>Decoded struct will be the result of calling decode (Adapt) on the log trigger result.
// Indexed dynamic type fields will be of type common.Hash.

type RateDataUpdateTopics struct {
	Reserve common.Address
}

type RateDataUpdateDecoded struct {
	Reserve                common.Address
	OptimalUsageRatio      *big.Int
	BaseVariableBorrowRate *big.Int
	VariableRateSlope1     *big.Int
	VariableRateSlope2     *big.Int
}

// Main Binding Type for DefaultReserveInterestRateStrategyV2
type DefaultReserveInterestRateStrategyV2 struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   DefaultReserveInterestRateStrategyV2Codec
}

type DefaultReserveInterestRateStrategyV2Codec interface {
	EncodeADDRESSESPROVIDERMethodCall() ([]byte, error)
	DecodeADDRESSESPROVIDERMethodOutput(data []byte) (common.Address, error)
	EncodeMAXBORROWRATEMethodCall() ([]byte, error)
	DecodeMAXBORROWRATEMethodOutput(data []byte) (*big.Int, error)
	EncodeMAXOPTIMALPOINTMethodCall() ([]byte, error)
	DecodeMAXOPTIMALPOINTMethodOutput(data []byte) (*big.Int, error)
	EncodeMINOPTIMALPOINTMethodCall() ([]byte, error)
	DecodeMINOPTIMALPOINTMethodOutput(data []byte) (*big.Int, error)
	EncodeCalculateInterestRatesMethodCall(in CalculateInterestRatesInput) ([]byte, error)
	DecodeCalculateInterestRatesMethodOutput(data []byte) (CalculateInterestRatesOutput, error)
	EncodeGetBaseVariableBorrowRateMethodCall(in GetBaseVariableBorrowRateInput) ([]byte, error)
	DecodeGetBaseVariableBorrowRateMethodOutput(data []byte) (*big.Int, error)
	EncodeGetInterestRateDataMethodCall(in GetInterestRateDataInput) ([]byte, error)
	DecodeGetInterestRateDataMethodOutput(data []byte) (IDefaultInterestRateStrategyV2InterestRateDataRay, error)
	EncodeGetInterestRateDataBpsMethodCall(in GetInterestRateDataBpsInput) ([]byte, error)
	DecodeGetInterestRateDataBpsMethodOutput(data []byte) (IDefaultInterestRateStrategyV2InterestRateData, error)
	EncodeGetMaxVariableBorrowRateMethodCall(in GetMaxVariableBorrowRateInput) ([]byte, error)
	DecodeGetMaxVariableBorrowRateMethodOutput(data []byte) (*big.Int, error)
	EncodeGetOptimalUsageRatioMethodCall(in GetOptimalUsageRatioInput) ([]byte, error)
	DecodeGetOptimalUsageRatioMethodOutput(data []byte) (*big.Int, error)
	EncodeGetVariableRateSlope1MethodCall(in GetVariableRateSlope1Input) ([]byte, error)
	DecodeGetVariableRateSlope1MethodOutput(data []byte) (*big.Int, error)
	EncodeGetVariableRateSlope2MethodCall(in GetVariableRateSlope2Input) ([]byte, error)
	DecodeGetVariableRateSlope2MethodOutput(data []byte) (*big.Int, error)
	EncodeSetInterestRateParamsMethodCall(in SetInterestRateParamsInput) ([]byte, error)
	EncodeSetInterestRateParams0MethodCall(in SetInterestRateParams0Input) ([]byte, error)
	EncodeDataTypesCalculateInterestRatesParamsStruct(in DataTypesCalculateInterestRatesParams) ([]byte, error)
	EncodeIDefaultInterestRateStrategyV2InterestRateDataStruct(in IDefaultInterestRateStrategyV2InterestRateData) ([]byte, error)
	EncodeIDefaultInterestRateStrategyV2InterestRateDataRayStruct(in IDefaultInterestRateStrategyV2InterestRateDataRay) ([]byte, error)
	RateDataUpdateLogHash() []byte
	EncodeRateDataUpdateTopics(evt abi.Event, values []RateDataUpdateTopics) ([]*evm.TopicValues, error)
	DecodeRateDataUpdate(log *evm.Log) (*RateDataUpdateDecoded, error)
}

func NewDefaultReserveInterestRateStrategyV2(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*DefaultReserveInterestRateStrategyV2, error) {
	parsed, err := abi.JSON(strings.NewReader(DefaultReserveInterestRateStrategyV2MetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &DefaultReserveInterestRateStrategyV2{
		Address: address,
		Options: options,
		ABI:     &parsed,
		client:  client,
		Codec:   codec,
	}, nil
}

type Codec struct {
	abi *abi.ABI
}

func NewCodec() (DefaultReserveInterestRateStrategyV2Codec, error) {
	parsed, err := abi.JSON(strings.NewReader(DefaultReserveInterestRateStrategyV2MetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeADDRESSESPROVIDERMethodCall() ([]byte, error) {
	return c.abi.Pack("ADDRESSES_PROVIDER")
}

func (c *Codec) DecodeADDRESSESPROVIDERMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["ADDRESSES_PROVIDER"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeMAXBORROWRATEMethodCall() ([]byte, error) {
	return c.abi.Pack("MAX_BORROW_RATE")
}

func (c *Codec) DecodeMAXBORROWRATEMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["MAX_BORROW_RATE"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeMAXOPTIMALPOINTMethodCall() ([]byte, error) {
	return c.abi.Pack("MAX_OPTIMAL_POINT")
}

func (c *Codec) DecodeMAXOPTIMALPOINTMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["MAX_OPTIMAL_POINT"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeMINOPTIMALPOINTMethodCall() ([]byte, error) {
	return c.abi.Pack("MIN_OPTIMAL_POINT")
}

func (c *Codec) DecodeMINOPTIMALPOINTMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["MIN_OPTIMAL_POINT"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeCalculateInterestRatesMethodCall(in CalculateInterestRatesInput) ([]byte, error) {
	return c.abi.Pack("calculateInterestRates", in.Params)
}

func (c *Codec) DecodeCalculateInterestRatesMethodOutput(data []byte) (CalculateInterestRatesOutput, error) {
	vals, err := c.abi.Methods["calculateInterestRates"].Outputs.Unpack(data)
	if err != nil {
		return CalculateInterestRatesOutput{}, err
	}
	if len(vals) != 2 {
		return CalculateInterestRatesOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return CalculateInterestRatesOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return CalculateInterestRatesOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return CalculateInterestRatesOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return CalculateInterestRatesOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return CalculateInterestRatesOutput{
		Arg0: result0,
		Arg1: result1,
	}, nil
}

func (c *Codec) EncodeGetBaseVariableBorrowRateMethodCall(in GetBaseVariableBorrowRateInput) ([]byte, error) {
	return c.abi.Pack("getBaseVariableBorrowRate", in.Reserve)
}

func (c *Codec) DecodeGetBaseVariableBorrowRateMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getBaseVariableBorrowRate"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetInterestRateDataMethodCall(in GetInterestRateDataInput) ([]byte, error) {
	return c.abi.Pack("getInterestRateData", in.Reserve)
}

func (c *Codec) DecodeGetInterestRateDataMethodOutput(data []byte) (IDefaultInterestRateStrategyV2InterestRateDataRay, error) {
	vals, err := c.abi.Methods["getInterestRateData"].Outputs.Unpack(data)
	if err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateDataRay), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateDataRay), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result IDefaultInterestRateStrategyV2InterestRateDataRay
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateDataRay), fmt.Errorf("failed to unmarshal to IDefaultInterestRateStrategyV2InterestRateDataRay: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetInterestRateDataBpsMethodCall(in GetInterestRateDataBpsInput) ([]byte, error) {
	return c.abi.Pack("getInterestRateDataBps", in.Reserve)
}

func (c *Codec) DecodeGetInterestRateDataBpsMethodOutput(data []byte) (IDefaultInterestRateStrategyV2InterestRateData, error) {
	vals, err := c.abi.Methods["getInterestRateDataBps"].Outputs.Unpack(data)
	if err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateData), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateData), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result IDefaultInterestRateStrategyV2InterestRateData
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(IDefaultInterestRateStrategyV2InterestRateData), fmt.Errorf("failed to unmarshal to IDefaultInterestRateStrategyV2InterestRateData: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetMaxVariableBorrowRateMethodCall(in GetMaxVariableBorrowRateInput) ([]byte, error) {
	return c.abi.Pack("getMaxVariableBorrowRate", in.Reserve)
}

func (c *Codec) DecodeGetMaxVariableBorrowRateMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getMaxVariableBorrowRate"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetOptimalUsageRatioMethodCall(in GetOptimalUsageRatioInput) ([]byte, error) {
	return c.abi.Pack("getOptimalUsageRatio", in.Reserve)
}

func (c *Codec) DecodeGetOptimalUsageRatioMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getOptimalUsageRatio"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetVariableRateSlope1MethodCall(in GetVariableRateSlope1Input) ([]byte, error) {
	return c.abi.Pack("getVariableRateSlope1", in.Reserve)
}

func (c *Codec) DecodeGetVariableRateSlope1MethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getVariableRateSlope1"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetVariableRateSlope2MethodCall(in GetVariableRateSlope2Input) ([]byte, error) {
	return c.abi.Pack("getVariableRateSlope2", in.Reserve)
}

func (c *Codec) DecodeGetVariableRateSlope2MethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getVariableRateSlope2"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeSetInterestRateParamsMethodCall(in SetInterestRateParamsInput) ([]byte, error) {
	return c.abi.Pack("setInterestRateParams", in.Reserve, in.RateData)
}

func (c *Codec) EncodeSetInterestRateParams0MethodCall(in SetInterestRateParams0Input) ([]byte, error) {
	return c.abi.Pack("setInterestRateParams0", in.Reserve, in.RateData)
}

func (c *Codec) EncodeDataTypesCalculateInterestRatesParamsStruct(in DataTypesCalculateInterestRatesParams) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "unbacked", Type: "uint256"},
			{Name: "liquidityAdded", Type: "uint256"},
			{Name: "liquidityTaken", Type: "uint256"},
			{Name: "totalDebt", Type: "uint256"},
			{Name: "reserveFactor", Type: "uint256"},
			{Name: "reserve", Type: "address"},
			{Name: "usingVirtualBalance", Type: "bool"},
			{Name: "virtualUnderlyingBalance", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for DataTypesCalculateInterestRatesParams: %w", err)
	}
	args := abi.Arguments{
		{Name: "dataTypesCalculateInterestRatesParams", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeIDefaultInterestRateStrategyV2InterestRateDataStruct(in IDefaultInterestRateStrategyV2InterestRateData) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "optimalUsageRatio", Type: "uint16"},
			{Name: "baseVariableBorrowRate", Type: "uint32"},
			{Name: "variableRateSlope1", Type: "uint32"},
			{Name: "variableRateSlope2", Type: "uint32"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for IDefaultInterestRateStrategyV2InterestRateData: %w", err)
	}
	args := abi.Arguments{
		{Name: "iDefaultInterestRateStrategyV2InterestRateData", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeIDefaultInterestRateStrategyV2InterestRateDataRayStruct(in IDefaultInterestRateStrategyV2InterestRateDataRay) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "optimalUsageRatio", Type: "uint256"},
			{Name: "baseVariableBorrowRate", Type: "uint256"},
			{Name: "variableRateSlope1", Type: "uint256"},
			{Name: "variableRateSlope2", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for IDefaultInterestRateStrategyV2InterestRateDataRay: %w", err)
	}
	args := abi.Arguments{
		{Name: "iDefaultInterestRateStrategyV2InterestRateDataRay", Type: tupleType},
	}

	return args.Pack(in)
}

func (c *Codec) RateDataUpdateLogHash() []byte {
	return c.abi.Events["RateDataUpdate"].ID.Bytes()
}

func (c *Codec) EncodeRateDataUpdateTopics(
	evt abi.Event,
	values []RateDataUpdateTopics,
) ([]*evm.TopicValues, error) {
	var reserveRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Reserve).IsZero() {
			reserveRule = append(reserveRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Reserve)
		if err != nil {
			return nil, err
		}
		reserveRule = append(reserveRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		reserveRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRateDataUpdate decodes a log into a RateDataUpdate struct.
func (c *Codec) DecodeRateDataUpdate(log *evm.Log) (*RateDataUpdateDecoded, error) {
	event := new(RateDataUpdateDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RateDataUpdate", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RateDataUpdate"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c DefaultReserveInterestRateStrategyV2) ADDRESSESPROVIDER(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeADDRESSESPROVIDERMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeADDRESSESPROVIDERMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) MAXBORROWRATE(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeMAXBORROWRATEMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeMAXBORROWRATEMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) MAXOPTIMALPOINT(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeMAXOPTIMALPOINTMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeMAXOPTIMALPOINTMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) MINOPTIMALPOINT(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeMINOPTIMALPOINTMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeMINOPTIMALPOINTMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) CalculateInterestRates(
	runtime cre.Runtime,
	args CalculateInterestRatesInput,
	blockNumber *big.Int,
) cre.Promise[CalculateInterestRatesOutput] {
	calldata, err := c.Codec.EncodeCalculateInterestRatesMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[CalculateInterestRatesOutput](CalculateInterestRatesOutput{}, err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (CalculateInterestRatesOutput, error) {
		return c.Codec.DecodeCalculateInterestRatesMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetBaseVariableBorrowRate(
	runtime cre.Runtime,
	args GetBaseVariableBorrowRateInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetBaseVariableBorrowRateMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetBaseVariableBorrowRateMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetInterestRateData(
	runtime cre.Runtime,
	args GetInterestRateDataInput,
	blockNumber *big.Int,
) cre.Promise[IDefaultInterestRateStrategyV2InterestRateDataRay] {
	calldata, err := c.Codec.EncodeGetInterestRateDataMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[IDefaultInterestRateStrategyV2InterestRateDataRay](*new(IDefaultInterestRateStrategyV2InterestRateDataRay), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (IDefaultInterestRateStrategyV2InterestRateDataRay, error) {
		return c.Codec.DecodeGetInterestRateDataMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetInterestRateDataBps(
	runtime cre.Runtime,
	args GetInterestRateDataBpsInput,
	blockNumber *big.Int,
) cre.Promise[IDefaultInterestRateStrategyV2InterestRateData] {
	calldata, err := c.Codec.EncodeGetInterestRateDataBpsMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[IDefaultInterestRateStrategyV2InterestRateData](*new(IDefaultInterestRateStrategyV2InterestRateData), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (IDefaultInterestRateStrategyV2InterestRateData, error) {
		return c.Codec.DecodeGetInterestRateDataBpsMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetMaxVariableBorrowRate(
	runtime cre.Runtime,
	args GetMaxVariableBorrowRateInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetMaxVariableBorrowRateMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetMaxVariableBorrowRateMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetOptimalUsageRatio(
	runtime cre.Runtime,
	args GetOptimalUsageRatioInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetOptimalUsageRatioMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetOptimalUsageRatioMethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetVariableRateSlope1(
	runtime cre.Runtime,
	args GetVariableRateSlope1Input,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetVariableRateSlope1MethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetVariableRateSlope1MethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) GetVariableRateSlope2(
	runtime cre.Runtime,
	args GetVariableRateSlope2Input,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetVariableRateSlope2MethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetVariableRateSlope2MethodOutput(response.Data)
	})

}

func (c DefaultReserveInterestRateStrategyV2) WriteReportFromDataTypesCalculateInterestRatesParams(
	runtime cre.Runtime,
	input DataTypesCalculateInterestRatesParams,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeDataTypesCalculateInterestRatesParamsStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c DefaultReserveInterestRateStrategyV2) WriteReportFromIDefaultInterestRateStrategyV2InterestRateData(
	runtime cre.Runtime,
	input IDefaultInterestRateStrategyV2InterestRateData,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeIDefaultInterestRateStrategyV2InterestRateDataStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c DefaultReserveInterestRateStrategyV2) WriteReportFromIDefaultInterestRateStrategyV2InterestRateDataRay(
	runtime cre.Runtime,
	input IDefaultInterestRateStrategyV2InterestRateDataRay,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeIDefaultInterestRateStrategyV2InterestRateDataRayStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c DefaultReserveInterestRateStrategyV2) WriteReport(
	runtime cre.Runtime,
	report *cre.Report,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
		Receiver:  c.Address.Bytes(),
		Report:    report,
		GasConfig: gasConfig,
	})
}

func (c *DefaultReserveInterestRateStrategyV2) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	default:
		return nil, errors.New("unknown error selector")
	}
}

// RateDataUpdateTrigger wraps the raw log trigger and provides decoded RateDataUpdateDecoded data
type RateDataUpdateTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                                       // Embed the raw trigger
	contract                        *DefaultReserveInterestRateStrategyV2 // Keep reference for decoding
}

// Adapt method that decodes the log into RateDataUpdate data
func (t *RateDataUpdateTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RateDataUpdateDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRateDataUpdate(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RateDataUpdate log: %w", err)
	}

	return &bindings.DecodedLog[RateDataUpdateDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *DefaultReserveInterestRateStrategyV2) LogTriggerRateDataUpdateLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RateDataUpdateTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RateDataUpdateDecoded]], error) {
	event := c.ABI.Events["RateDataUpdate"]
	topics, err := c.Codec.EncodeRateDataUpdateTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RateDataUpdate: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RateDataUpdateTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *DefaultReserveInterestRateStrategyV2) FilterLogsRateDataUpdate(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RateDataUpdateLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}
