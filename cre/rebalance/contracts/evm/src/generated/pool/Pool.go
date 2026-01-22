// Code generated — DO NOT EDIT.

package pool

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

var PoolMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveData\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"configuration\",\"type\":\"uint256\"},{\"internalType\":\"uint128\",\"name\":\"liquidityIndex\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"currentLiquidityRate\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"variableBorrowIndex\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"currentVariableBorrowRate\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"currentStableBorrowRate\",\"type\":\"uint128\"},{\"internalType\":\"uint40\",\"name\":\"lastUpdateTimestamp\",\"type\":\"uint40\"},{\"internalType\":\"address\",\"name\":\"aTokenAddress\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"stableDebtTokenAddress\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"variableDebtTokenAddress\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"interestRateStrategyAddress\",\"type\":\"address\"},{\"internalType\":\"uint128\",\"name\":\"accruedToTreasury\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"unbacked\",\"type\":\"uint128\"},{\"internalType\":\"uint128\",\"name\":\"isolationModeTotalDebt\",\"type\":\"uint128\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
}

// Structs

// Contract Method Inputs
type GetReserveDataInput struct {
	Asset common.Address
}

// Contract Method Outputs
type GetReserveDataOutput struct {
	Configuration               *big.Int
	LiquidityIndex              *big.Int
	CurrentLiquidityRate        *big.Int
	VariableBorrowIndex         *big.Int
	CurrentVariableBorrowRate   *big.Int
	CurrentStableBorrowRate     *big.Int
	LastUpdateTimestamp         *big.Int
	ATokenAddress               common.Address
	StableDebtTokenAddress      common.Address
	VariableDebtTokenAddress    common.Address
	InterestRateStrategyAddress common.Address
	AccruedToTreasury           *big.Int
	Unbacked                    *big.Int
	IsolationModeTotalDebt      *big.Int
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

// Main Binding Type for Pool
type Pool struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   PoolCodec
}

type PoolCodec interface {
	EncodeGetReserveDataMethodCall(in GetReserveDataInput) ([]byte, error)
	DecodeGetReserveDataMethodOutput(data []byte) (GetReserveDataOutput, error)
}

func NewPool(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*Pool, error) {
	parsed, err := abi.JSON(strings.NewReader(PoolMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &Pool{
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

func NewCodec() (PoolCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(PoolMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeGetReserveDataMethodCall(in GetReserveDataInput) ([]byte, error) {
	return c.abi.Pack("getReserveData", in.Asset)
}

func (c *Codec) DecodeGetReserveDataMethodOutput(data []byte) (GetReserveDataOutput, error) {
	vals, err := c.abi.Methods["getReserveData"].Outputs.Unpack(data)
	if err != nil {
		return GetReserveDataOutput{}, err
	}
	if len(vals) != 14 {
		return GetReserveDataOutput{}, fmt.Errorf("expected 14 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 *big.Int
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData3, err := json.Marshal(vals[3])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 3: %w", err)
	}

	var result3 *big.Int
	if err := json.Unmarshal(jsonData3, &result3); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData4, err := json.Marshal(vals[4])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 4: %w", err)
	}

	var result4 *big.Int
	if err := json.Unmarshal(jsonData4, &result4); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData5, err := json.Marshal(vals[5])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 5: %w", err)
	}

	var result5 *big.Int
	if err := json.Unmarshal(jsonData5, &result5); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData6, err := json.Marshal(vals[6])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 6: %w", err)
	}

	var result6 *big.Int
	if err := json.Unmarshal(jsonData6, &result6); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData7, err := json.Marshal(vals[7])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 7: %w", err)
	}

	var result7 common.Address
	if err := json.Unmarshal(jsonData7, &result7); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData8, err := json.Marshal(vals[8])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 8: %w", err)
	}

	var result8 common.Address
	if err := json.Unmarshal(jsonData8, &result8); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData9, err := json.Marshal(vals[9])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 9: %w", err)
	}

	var result9 common.Address
	if err := json.Unmarshal(jsonData9, &result9); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData10, err := json.Marshal(vals[10])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 10: %w", err)
	}

	var result10 common.Address
	if err := json.Unmarshal(jsonData10, &result10); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData11, err := json.Marshal(vals[11])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 11: %w", err)
	}

	var result11 *big.Int
	if err := json.Unmarshal(jsonData11, &result11); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData12, err := json.Marshal(vals[12])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 12: %w", err)
	}

	var result12 *big.Int
	if err := json.Unmarshal(jsonData12, &result12); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData13, err := json.Marshal(vals[13])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 13: %w", err)
	}

	var result13 *big.Int
	if err := json.Unmarshal(jsonData13, &result13); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return GetReserveDataOutput{
		Configuration:               result0,
		LiquidityIndex:              result1,
		CurrentLiquidityRate:        result2,
		VariableBorrowIndex:         result3,
		CurrentVariableBorrowRate:   result4,
		CurrentStableBorrowRate:     result5,
		LastUpdateTimestamp:         result6,
		ATokenAddress:               result7,
		StableDebtTokenAddress:      result8,
		VariableDebtTokenAddress:    result9,
		InterestRateStrategyAddress: result10,
		AccruedToTreasury:           result11,
		Unbacked:                    result12,
		IsolationModeTotalDebt:      result13,
	}, nil
}

func (c Pool) GetReserveData(
	runtime cre.Runtime,
	args GetReserveDataInput,
	blockNumber *big.Int,
) cre.Promise[GetReserveDataOutput] {
	calldata, err := c.Codec.EncodeGetReserveDataMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetReserveDataOutput](GetReserveDataOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (GetReserveDataOutput, error) {
		return c.Codec.DecodeGetReserveDataMethodOutput(response.Data)
	})

}

func (c Pool) WriteReport(
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

func (c *Pool) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	default:
		return nil, errors.New("unknown error selector")
	}
}