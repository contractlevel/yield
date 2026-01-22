// Code generated — DO NOT EDIT.

package aave_protocol_data_provider

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

var AaveProtocolDataProviderMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"contractIPoolAddressesProvider\",\"name\":\"addressesProvider\",\"type\":\"address\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"inputs\":[],\"name\":\"InvalidReserveIndex\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"ZeroAddressNotValid\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"ADDRESSES_PROVIDER\",\"outputs\":[{\"internalType\":\"contractIPoolAddressesProvider\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"POOL\",\"outputs\":[{\"internalType\":\"contractIPool\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getATokenTotalSupply\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAllATokens\",\"outputs\":[{\"components\":[{\"internalType\":\"string\",\"name\":\"symbol\",\"type\":\"string\"},{\"internalType\":\"address\",\"name\":\"tokenAddress\",\"type\":\"address\"}],\"internalType\":\"structIPoolDataProvider.TokenData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAllReservesTokens\",\"outputs\":[{\"components\":[{\"internalType\":\"string\",\"name\":\"symbol\",\"type\":\"string\"},{\"internalType\":\"address\",\"name\":\"tokenAddress\",\"type\":\"address\"}],\"internalType\":\"structIPoolDataProvider.TokenData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getDebtCeiling\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getDebtCeilingDecimals\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"pure\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getFlashLoanEnabled\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"name\":\"getInterestRateStrategyAddress\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"irStrategyAddress\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"name\":\"getIsVirtualAccActive\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"pure\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getLiquidationProtocolFee\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getPaused\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"isPaused\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveCaps\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"borrowCap\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"supplyCap\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveConfigurationData\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"ltv\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidationThreshold\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidationBonus\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"reserveFactor\",\"type\":\"uint256\"},{\"internalType\":\"bool\",\"name\":\"usageAsCollateralEnabled\",\"type\":\"bool\"},{\"internalType\":\"bool\",\"name\":\"borrowingEnabled\",\"type\":\"bool\"},{\"internalType\":\"bool\",\"name\":\"stableBorrowRateEnabled\",\"type\":\"bool\"},{\"internalType\":\"bool\",\"name\":\"isActive\",\"type\":\"bool\"},{\"internalType\":\"bool\",\"name\":\"isFrozen\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveData\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"accruedToTreasuryScaled\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"totalAToken\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"totalVariableDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidityRate\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"variableBorrowRate\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidityIndex\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"variableBorrowIndex\",\"type\":\"uint256\"},{\"internalType\":\"uint40\",\"name\":\"lastUpdateTimestamp\",\"type\":\"uint40\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveDeficit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getReserveTokensAddresses\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"aTokenAddress\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"stableDebtTokenAddress\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"variableDebtTokenAddress\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getSiloedBorrowing\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getTotalDebt\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"name\":\"getUnbackedMintCap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"pure\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"user\",\"type\":\"address\"}],\"name\":\"getUserReserveData\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"currentATokenBalance\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"currentStableDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"currentVariableDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"principalStableDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"scaledVariableDebt\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"stableBorrowRate\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"liquidityRate\",\"type\":\"uint256\"},{\"internalType\":\"uint40\",\"name\":\"stableRateLastUpdated\",\"type\":\"uint40\"},{\"internalType\":\"bool\",\"name\":\"usageAsCollateralEnabled\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\"}],\"name\":\"getVirtualUnderlyingBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
}

// Structs
type IPoolDataProviderTokenData struct {
	Symbol       string
	TokenAddress common.Address
}

// Contract Method Inputs
type GetATokenTotalSupplyInput struct {
	Asset common.Address
}

type GetDebtCeilingInput struct {
	Asset common.Address
}

type GetFlashLoanEnabledInput struct {
	Asset common.Address
}

type GetInterestRateStrategyAddressInput struct {
	Arg0 common.Address
}

type GetIsVirtualAccActiveInput struct {
	Arg0 common.Address
}

type GetLiquidationProtocolFeeInput struct {
	Asset common.Address
}

type GetPausedInput struct {
	Asset common.Address
}

type GetReserveCapsInput struct {
	Asset common.Address
}

type GetReserveConfigurationDataInput struct {
	Asset common.Address
}

type GetReserveDataInput struct {
	Asset common.Address
}

type GetReserveDeficitInput struct {
	Asset common.Address
}

type GetReserveTokensAddressesInput struct {
	Asset common.Address
}

type GetSiloedBorrowingInput struct {
	Asset common.Address
}

type GetTotalDebtInput struct {
	Asset common.Address
}

type GetUnbackedMintCapInput struct {
	Arg0 common.Address
}

type GetUserReserveDataInput struct {
	Asset common.Address
	User  common.Address
}

type GetVirtualUnderlyingBalanceInput struct {
	Asset common.Address
}

// Contract Method Outputs
type GetReserveCapsOutput struct {
	BorrowCap *big.Int
	SupplyCap *big.Int
}

type GetReserveConfigurationDataOutput struct {
	Decimals                 *big.Int
	Ltv                      *big.Int
	LiquidationThreshold     *big.Int
	LiquidationBonus         *big.Int
	ReserveFactor            *big.Int
	UsageAsCollateralEnabled bool
	BorrowingEnabled         bool
	StableBorrowRateEnabled  bool
	IsActive                 bool
	IsFrozen                 bool
}

type GetReserveDataOutput struct {
	Arg0                    *big.Int
	AccruedToTreasuryScaled *big.Int
	TotalAToken             *big.Int
	Arg3                    *big.Int
	TotalVariableDebt       *big.Int
	LiquidityRate           *big.Int
	VariableBorrowRate      *big.Int
	Arg7                    *big.Int
	Arg8                    *big.Int
	LiquidityIndex          *big.Int
	VariableBorrowIndex     *big.Int
	LastUpdateTimestamp     *big.Int
}

type GetReserveTokensAddressesOutput struct {
	ATokenAddress            common.Address
	StableDebtTokenAddress   common.Address
	VariableDebtTokenAddress common.Address
}

type GetUserReserveDataOutput struct {
	CurrentATokenBalance     *big.Int
	CurrentStableDebt        *big.Int
	CurrentVariableDebt      *big.Int
	PrincipalStableDebt      *big.Int
	ScaledVariableDebt       *big.Int
	StableBorrowRate         *big.Int
	LiquidityRate            *big.Int
	StableRateLastUpdated    *big.Int
	UsageAsCollateralEnabled bool
}

// Errors
type InvalidReserveIndex struct {
}

type ZeroAddressNotValid struct {
}

// Events
// The <Event>Topics struct should be used as a filter (for log triggers).
// Note: It is only possible to filter on indexed fields.
// Indexed (string and bytes) fields will be of type common.Hash.
// They need to he (crypto.Keccak256) hashed and passed in.
// Indexed (tuple/slice/array) fields can be passed in as is, the Encode<Event>Topics function will handle the hashing.
//
// The <Event>Decoded struct will be the result of calling decode (Adapt) on the log trigger result.
// Indexed dynamic type fields will be of type common.Hash.

// Main Binding Type for AaveProtocolDataProvider
type AaveProtocolDataProvider struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   AaveProtocolDataProviderCodec
}

type AaveProtocolDataProviderCodec interface {
	EncodeADDRESSESPROVIDERMethodCall() ([]byte, error)
	DecodeADDRESSESPROVIDERMethodOutput(data []byte) (common.Address, error)
	EncodePOOLMethodCall() ([]byte, error)
	DecodePOOLMethodOutput(data []byte) (common.Address, error)
	EncodeGetATokenTotalSupplyMethodCall(in GetATokenTotalSupplyInput) ([]byte, error)
	DecodeGetATokenTotalSupplyMethodOutput(data []byte) (*big.Int, error)
	EncodeGetAllATokensMethodCall() ([]byte, error)
	DecodeGetAllATokensMethodOutput(data []byte) ([]IPoolDataProviderTokenData, error)
	EncodeGetAllReservesTokensMethodCall() ([]byte, error)
	DecodeGetAllReservesTokensMethodOutput(data []byte) ([]IPoolDataProviderTokenData, error)
	EncodeGetDebtCeilingMethodCall(in GetDebtCeilingInput) ([]byte, error)
	DecodeGetDebtCeilingMethodOutput(data []byte) (*big.Int, error)
	EncodeGetDebtCeilingDecimalsMethodCall() ([]byte, error)
	DecodeGetDebtCeilingDecimalsMethodOutput(data []byte) (*big.Int, error)
	EncodeGetFlashLoanEnabledMethodCall(in GetFlashLoanEnabledInput) ([]byte, error)
	DecodeGetFlashLoanEnabledMethodOutput(data []byte) (bool, error)
	EncodeGetInterestRateStrategyAddressMethodCall(in GetInterestRateStrategyAddressInput) ([]byte, error)
	DecodeGetInterestRateStrategyAddressMethodOutput(data []byte) (common.Address, error)
	EncodeGetIsVirtualAccActiveMethodCall(in GetIsVirtualAccActiveInput) ([]byte, error)
	DecodeGetIsVirtualAccActiveMethodOutput(data []byte) (bool, error)
	EncodeGetLiquidationProtocolFeeMethodCall(in GetLiquidationProtocolFeeInput) ([]byte, error)
	DecodeGetLiquidationProtocolFeeMethodOutput(data []byte) (*big.Int, error)
	EncodeGetPausedMethodCall(in GetPausedInput) ([]byte, error)
	DecodeGetPausedMethodOutput(data []byte) (bool, error)
	EncodeGetReserveCapsMethodCall(in GetReserveCapsInput) ([]byte, error)
	DecodeGetReserveCapsMethodOutput(data []byte) (GetReserveCapsOutput, error)
	EncodeGetReserveConfigurationDataMethodCall(in GetReserveConfigurationDataInput) ([]byte, error)
	DecodeGetReserveConfigurationDataMethodOutput(data []byte) (GetReserveConfigurationDataOutput, error)
	EncodeGetReserveDataMethodCall(in GetReserveDataInput) ([]byte, error)
	DecodeGetReserveDataMethodOutput(data []byte) (GetReserveDataOutput, error)
	EncodeGetReserveDeficitMethodCall(in GetReserveDeficitInput) ([]byte, error)
	DecodeGetReserveDeficitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetReserveTokensAddressesMethodCall(in GetReserveTokensAddressesInput) ([]byte, error)
	DecodeGetReserveTokensAddressesMethodOutput(data []byte) (GetReserveTokensAddressesOutput, error)
	EncodeGetSiloedBorrowingMethodCall(in GetSiloedBorrowingInput) ([]byte, error)
	DecodeGetSiloedBorrowingMethodOutput(data []byte) (bool, error)
	EncodeGetTotalDebtMethodCall(in GetTotalDebtInput) ([]byte, error)
	DecodeGetTotalDebtMethodOutput(data []byte) (*big.Int, error)
	EncodeGetUnbackedMintCapMethodCall(in GetUnbackedMintCapInput) ([]byte, error)
	DecodeGetUnbackedMintCapMethodOutput(data []byte) (*big.Int, error)
	EncodeGetUserReserveDataMethodCall(in GetUserReserveDataInput) ([]byte, error)
	DecodeGetUserReserveDataMethodOutput(data []byte) (GetUserReserveDataOutput, error)
	EncodeGetVirtualUnderlyingBalanceMethodCall(in GetVirtualUnderlyingBalanceInput) ([]byte, error)
	DecodeGetVirtualUnderlyingBalanceMethodOutput(data []byte) (*big.Int, error)
	EncodeIPoolDataProviderTokenDataStruct(in IPoolDataProviderTokenData) ([]byte, error)
}

func NewAaveProtocolDataProvider(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*AaveProtocolDataProvider, error) {
	parsed, err := abi.JSON(strings.NewReader(AaveProtocolDataProviderMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &AaveProtocolDataProvider{
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

func NewCodec() (AaveProtocolDataProviderCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(AaveProtocolDataProviderMetaData.ABI))
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

func (c *Codec) EncodePOOLMethodCall() ([]byte, error) {
	return c.abi.Pack("POOL")
}

func (c *Codec) DecodePOOLMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["POOL"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetATokenTotalSupplyMethodCall(in GetATokenTotalSupplyInput) ([]byte, error) {
	return c.abi.Pack("getATokenTotalSupply", in.Asset)
}

func (c *Codec) DecodeGetATokenTotalSupplyMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getATokenTotalSupply"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetAllATokensMethodCall() ([]byte, error) {
	return c.abi.Pack("getAllATokens")
}

func (c *Codec) DecodeGetAllATokensMethodOutput(data []byte) ([]IPoolDataProviderTokenData, error) {
	vals, err := c.abi.Methods["getAllATokens"].Outputs.Unpack(data)
	if err != nil {
		return *new([]IPoolDataProviderTokenData), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([]IPoolDataProviderTokenData), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result []IPoolDataProviderTokenData
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([]IPoolDataProviderTokenData), fmt.Errorf("failed to unmarshal to []IPoolDataProviderTokenData: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetAllReservesTokensMethodCall() ([]byte, error) {
	return c.abi.Pack("getAllReservesTokens")
}

func (c *Codec) DecodeGetAllReservesTokensMethodOutput(data []byte) ([]IPoolDataProviderTokenData, error) {
	vals, err := c.abi.Methods["getAllReservesTokens"].Outputs.Unpack(data)
	if err != nil {
		return *new([]IPoolDataProviderTokenData), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([]IPoolDataProviderTokenData), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result []IPoolDataProviderTokenData
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([]IPoolDataProviderTokenData), fmt.Errorf("failed to unmarshal to []IPoolDataProviderTokenData: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetDebtCeilingMethodCall(in GetDebtCeilingInput) ([]byte, error) {
	return c.abi.Pack("getDebtCeiling", in.Asset)
}

func (c *Codec) DecodeGetDebtCeilingMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getDebtCeiling"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetDebtCeilingDecimalsMethodCall() ([]byte, error) {
	return c.abi.Pack("getDebtCeilingDecimals")
}

func (c *Codec) DecodeGetDebtCeilingDecimalsMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getDebtCeilingDecimals"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetFlashLoanEnabledMethodCall(in GetFlashLoanEnabledInput) ([]byte, error) {
	return c.abi.Pack("getFlashLoanEnabled", in.Asset)
}

func (c *Codec) DecodeGetFlashLoanEnabledMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getFlashLoanEnabled"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetInterestRateStrategyAddressMethodCall(in GetInterestRateStrategyAddressInput) ([]byte, error) {
	return c.abi.Pack("getInterestRateStrategyAddress", in.Arg0)
}

func (c *Codec) DecodeGetInterestRateStrategyAddressMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getInterestRateStrategyAddress"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetIsVirtualAccActiveMethodCall(in GetIsVirtualAccActiveInput) ([]byte, error) {
	return c.abi.Pack("getIsVirtualAccActive", in.Arg0)
}

func (c *Codec) DecodeGetIsVirtualAccActiveMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getIsVirtualAccActive"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetLiquidationProtocolFeeMethodCall(in GetLiquidationProtocolFeeInput) ([]byte, error) {
	return c.abi.Pack("getLiquidationProtocolFee", in.Asset)
}

func (c *Codec) DecodeGetLiquidationProtocolFeeMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getLiquidationProtocolFee"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetPausedMethodCall(in GetPausedInput) ([]byte, error) {
	return c.abi.Pack("getPaused", in.Asset)
}

func (c *Codec) DecodeGetPausedMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getPaused"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetReserveCapsMethodCall(in GetReserveCapsInput) ([]byte, error) {
	return c.abi.Pack("getReserveCaps", in.Asset)
}

func (c *Codec) DecodeGetReserveCapsMethodOutput(data []byte) (GetReserveCapsOutput, error) {
	vals, err := c.abi.Methods["getReserveCaps"].Outputs.Unpack(data)
	if err != nil {
		return GetReserveCapsOutput{}, err
	}
	if len(vals) != 2 {
		return GetReserveCapsOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetReserveCapsOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetReserveCapsOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetReserveCapsOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetReserveCapsOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return GetReserveCapsOutput{
		BorrowCap: result0,
		SupplyCap: result1,
	}, nil
}

func (c *Codec) EncodeGetReserveConfigurationDataMethodCall(in GetReserveConfigurationDataInput) ([]byte, error) {
	return c.abi.Pack("getReserveConfigurationData", in.Asset)
}

func (c *Codec) DecodeGetReserveConfigurationDataMethodOutput(data []byte) (GetReserveConfigurationDataOutput, error) {
	vals, err := c.abi.Methods["getReserveConfigurationData"].Outputs.Unpack(data)
	if err != nil {
		return GetReserveConfigurationDataOutput{}, err
	}
	if len(vals) != 10 {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("expected 10 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 *big.Int
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData3, err := json.Marshal(vals[3])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 3: %w", err)
	}

	var result3 *big.Int
	if err := json.Unmarshal(jsonData3, &result3); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData4, err := json.Marshal(vals[4])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 4: %w", err)
	}

	var result4 *big.Int
	if err := json.Unmarshal(jsonData4, &result4); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData5, err := json.Marshal(vals[5])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 5: %w", err)
	}

	var result5 bool
	if err := json.Unmarshal(jsonData5, &result5); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}
	jsonData6, err := json.Marshal(vals[6])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 6: %w", err)
	}

	var result6 bool
	if err := json.Unmarshal(jsonData6, &result6); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}
	jsonData7, err := json.Marshal(vals[7])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 7: %w", err)
	}

	var result7 bool
	if err := json.Unmarshal(jsonData7, &result7); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}
	jsonData8, err := json.Marshal(vals[8])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 8: %w", err)
	}

	var result8 bool
	if err := json.Unmarshal(jsonData8, &result8); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}
	jsonData9, err := json.Marshal(vals[9])
	if err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to marshal ABI result 9: %w", err)
	}

	var result9 bool
	if err := json.Unmarshal(jsonData9, &result9); err != nil {
		return GetReserveConfigurationDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return GetReserveConfigurationDataOutput{
		Decimals:                 result0,
		Ltv:                      result1,
		LiquidationThreshold:     result2,
		LiquidationBonus:         result3,
		ReserveFactor:            result4,
		UsageAsCollateralEnabled: result5,
		BorrowingEnabled:         result6,
		StableBorrowRateEnabled:  result7,
		IsActive:                 result8,
		IsFrozen:                 result9,
	}, nil
}

func (c *Codec) EncodeGetReserveDataMethodCall(in GetReserveDataInput) ([]byte, error) {
	return c.abi.Pack("getReserveData", in.Asset)
}

func (c *Codec) DecodeGetReserveDataMethodOutput(data []byte) (GetReserveDataOutput, error) {
	vals, err := c.abi.Methods["getReserveData"].Outputs.Unpack(data)
	if err != nil {
		return GetReserveDataOutput{}, err
	}
	if len(vals) != 12 {
		return GetReserveDataOutput{}, fmt.Errorf("expected 12 values, got %d", len(vals))
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

	var result7 *big.Int
	if err := json.Unmarshal(jsonData7, &result7); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData8, err := json.Marshal(vals[8])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 8: %w", err)
	}

	var result8 *big.Int
	if err := json.Unmarshal(jsonData8, &result8); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData9, err := json.Marshal(vals[9])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 9: %w", err)
	}

	var result9 *big.Int
	if err := json.Unmarshal(jsonData9, &result9); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData10, err := json.Marshal(vals[10])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 10: %w", err)
	}

	var result10 *big.Int
	if err := json.Unmarshal(jsonData10, &result10); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData11, err := json.Marshal(vals[11])
	if err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 11: %w", err)
	}

	var result11 *big.Int
	if err := json.Unmarshal(jsonData11, &result11); err != nil {
		return GetReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return GetReserveDataOutput{
		Arg0:                    result0,
		AccruedToTreasuryScaled: result1,
		TotalAToken:             result2,
		Arg3:                    result3,
		TotalVariableDebt:       result4,
		LiquidityRate:           result5,
		VariableBorrowRate:      result6,
		Arg7:                    result7,
		Arg8:                    result8,
		LiquidityIndex:          result9,
		VariableBorrowIndex:     result10,
		LastUpdateTimestamp:     result11,
	}, nil
}

func (c *Codec) EncodeGetReserveDeficitMethodCall(in GetReserveDeficitInput) ([]byte, error) {
	return c.abi.Pack("getReserveDeficit", in.Asset)
}

func (c *Codec) DecodeGetReserveDeficitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getReserveDeficit"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetReserveTokensAddressesMethodCall(in GetReserveTokensAddressesInput) ([]byte, error) {
	return c.abi.Pack("getReserveTokensAddresses", in.Asset)
}

func (c *Codec) DecodeGetReserveTokensAddressesMethodOutput(data []byte) (GetReserveTokensAddressesOutput, error) {
	vals, err := c.abi.Methods["getReserveTokensAddresses"].Outputs.Unpack(data)
	if err != nil {
		return GetReserveTokensAddressesOutput{}, err
	}
	if len(vals) != 3 {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("expected 3 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 common.Address
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 common.Address
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 common.Address
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return GetReserveTokensAddressesOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return GetReserveTokensAddressesOutput{
		ATokenAddress:            result0,
		StableDebtTokenAddress:   result1,
		VariableDebtTokenAddress: result2,
	}, nil
}

func (c *Codec) EncodeGetSiloedBorrowingMethodCall(in GetSiloedBorrowingInput) ([]byte, error) {
	return c.abi.Pack("getSiloedBorrowing", in.Asset)
}

func (c *Codec) DecodeGetSiloedBorrowingMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getSiloedBorrowing"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetTotalDebtMethodCall(in GetTotalDebtInput) ([]byte, error) {
	return c.abi.Pack("getTotalDebt", in.Asset)
}

func (c *Codec) DecodeGetTotalDebtMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getTotalDebt"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetUnbackedMintCapMethodCall(in GetUnbackedMintCapInput) ([]byte, error) {
	return c.abi.Pack("getUnbackedMintCap", in.Arg0)
}

func (c *Codec) DecodeGetUnbackedMintCapMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getUnbackedMintCap"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetUserReserveDataMethodCall(in GetUserReserveDataInput) ([]byte, error) {
	return c.abi.Pack("getUserReserveData", in.Asset, in.User)
}

func (c *Codec) DecodeGetUserReserveDataMethodOutput(data []byte) (GetUserReserveDataOutput, error) {
	vals, err := c.abi.Methods["getUserReserveData"].Outputs.Unpack(data)
	if err != nil {
		return GetUserReserveDataOutput{}, err
	}
	if len(vals) != 9 {
		return GetUserReserveDataOutput{}, fmt.Errorf("expected 9 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 *big.Int
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData3, err := json.Marshal(vals[3])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 3: %w", err)
	}

	var result3 *big.Int
	if err := json.Unmarshal(jsonData3, &result3); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData4, err := json.Marshal(vals[4])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 4: %w", err)
	}

	var result4 *big.Int
	if err := json.Unmarshal(jsonData4, &result4); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData5, err := json.Marshal(vals[5])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 5: %w", err)
	}

	var result5 *big.Int
	if err := json.Unmarshal(jsonData5, &result5); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData6, err := json.Marshal(vals[6])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 6: %w", err)
	}

	var result6 *big.Int
	if err := json.Unmarshal(jsonData6, &result6); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData7, err := json.Marshal(vals[7])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 7: %w", err)
	}

	var result7 *big.Int
	if err := json.Unmarshal(jsonData7, &result7); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData8, err := json.Marshal(vals[8])
	if err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to marshal ABI result 8: %w", err)
	}

	var result8 bool
	if err := json.Unmarshal(jsonData8, &result8); err != nil {
		return GetUserReserveDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return GetUserReserveDataOutput{
		CurrentATokenBalance:     result0,
		CurrentStableDebt:        result1,
		CurrentVariableDebt:      result2,
		PrincipalStableDebt:      result3,
		ScaledVariableDebt:       result4,
		StableBorrowRate:         result5,
		LiquidityRate:            result6,
		StableRateLastUpdated:    result7,
		UsageAsCollateralEnabled: result8,
	}, nil
}

func (c *Codec) EncodeGetVirtualUnderlyingBalanceMethodCall(in GetVirtualUnderlyingBalanceInput) ([]byte, error) {
	return c.abi.Pack("getVirtualUnderlyingBalance", in.Asset)
}

func (c *Codec) DecodeGetVirtualUnderlyingBalanceMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getVirtualUnderlyingBalance"].Outputs.Unpack(data)
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

func (c *Codec) EncodeIPoolDataProviderTokenDataStruct(in IPoolDataProviderTokenData) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "symbol", Type: "string"},
			{Name: "tokenAddress", Type: "address"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for IPoolDataProviderTokenData: %w", err)
	}
	args := abi.Arguments{
		{Name: "iPoolDataProviderTokenData", Type: tupleType},
	}

	return args.Pack(in)
}

func (c AaveProtocolDataProvider) ADDRESSESPROVIDER(
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

func (c AaveProtocolDataProvider) POOL(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodePOOLMethodCall()
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
		return c.Codec.DecodePOOLMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetATokenTotalSupply(
	runtime cre.Runtime,
	args GetATokenTotalSupplyInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetATokenTotalSupplyMethodCall(args)
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
		return c.Codec.DecodeGetATokenTotalSupplyMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetAllATokens(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[]IPoolDataProviderTokenData] {
	calldata, err := c.Codec.EncodeGetAllATokensMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[]IPoolDataProviderTokenData](*new([]IPoolDataProviderTokenData), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) ([]IPoolDataProviderTokenData, error) {
		return c.Codec.DecodeGetAllATokensMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetAllReservesTokens(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[]IPoolDataProviderTokenData] {
	calldata, err := c.Codec.EncodeGetAllReservesTokensMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[]IPoolDataProviderTokenData](*new([]IPoolDataProviderTokenData), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) ([]IPoolDataProviderTokenData, error) {
		return c.Codec.DecodeGetAllReservesTokensMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetDebtCeiling(
	runtime cre.Runtime,
	args GetDebtCeilingInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetDebtCeilingMethodCall(args)
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
		return c.Codec.DecodeGetDebtCeilingMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetFlashLoanEnabled(
	runtime cre.Runtime,
	args GetFlashLoanEnabledInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetFlashLoanEnabledMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodeGetFlashLoanEnabledMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetInterestRateStrategyAddress(
	runtime cre.Runtime,
	args GetInterestRateStrategyAddressInput,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetInterestRateStrategyAddressMethodCall(args)
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
		return c.Codec.DecodeGetInterestRateStrategyAddressMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetLiquidationProtocolFee(
	runtime cre.Runtime,
	args GetLiquidationProtocolFeeInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetLiquidationProtocolFeeMethodCall(args)
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
		return c.Codec.DecodeGetLiquidationProtocolFeeMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetPaused(
	runtime cre.Runtime,
	args GetPausedInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetPausedMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodeGetPausedMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetReserveCaps(
	runtime cre.Runtime,
	args GetReserveCapsInput,
	blockNumber *big.Int,
) cre.Promise[GetReserveCapsOutput] {
	calldata, err := c.Codec.EncodeGetReserveCapsMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetReserveCapsOutput](GetReserveCapsOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (GetReserveCapsOutput, error) {
		return c.Codec.DecodeGetReserveCapsMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetReserveConfigurationData(
	runtime cre.Runtime,
	args GetReserveConfigurationDataInput,
	blockNumber *big.Int,
) cre.Promise[GetReserveConfigurationDataOutput] {
	calldata, err := c.Codec.EncodeGetReserveConfigurationDataMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetReserveConfigurationDataOutput](GetReserveConfigurationDataOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (GetReserveConfigurationDataOutput, error) {
		return c.Codec.DecodeGetReserveConfigurationDataMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetReserveData(
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

func (c AaveProtocolDataProvider) GetReserveDeficit(
	runtime cre.Runtime,
	args GetReserveDeficitInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetReserveDeficitMethodCall(args)
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
		return c.Codec.DecodeGetReserveDeficitMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetReserveTokensAddresses(
	runtime cre.Runtime,
	args GetReserveTokensAddressesInput,
	blockNumber *big.Int,
) cre.Promise[GetReserveTokensAddressesOutput] {
	calldata, err := c.Codec.EncodeGetReserveTokensAddressesMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetReserveTokensAddressesOutput](GetReserveTokensAddressesOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (GetReserveTokensAddressesOutput, error) {
		return c.Codec.DecodeGetReserveTokensAddressesMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetSiloedBorrowing(
	runtime cre.Runtime,
	args GetSiloedBorrowingInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetSiloedBorrowingMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodeGetSiloedBorrowingMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetTotalDebt(
	runtime cre.Runtime,
	args GetTotalDebtInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetTotalDebtMethodCall(args)
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
		return c.Codec.DecodeGetTotalDebtMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetUserReserveData(
	runtime cre.Runtime,
	args GetUserReserveDataInput,
	blockNumber *big.Int,
) cre.Promise[GetUserReserveDataOutput] {
	calldata, err := c.Codec.EncodeGetUserReserveDataMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetUserReserveDataOutput](GetUserReserveDataOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (GetUserReserveDataOutput, error) {
		return c.Codec.DecodeGetUserReserveDataMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) GetVirtualUnderlyingBalance(
	runtime cre.Runtime,
	args GetVirtualUnderlyingBalanceInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetVirtualUnderlyingBalanceMethodCall(args)
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
		return c.Codec.DecodeGetVirtualUnderlyingBalanceMethodOutput(response.Data)
	})

}

func (c AaveProtocolDataProvider) WriteReportFromIPoolDataProviderTokenData(
	runtime cre.Runtime,
	input IPoolDataProviderTokenData,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeIPoolDataProviderTokenDataStruct(input)
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

func (c AaveProtocolDataProvider) WriteReport(
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

// DecodeInvalidReserveIndexError decodes a InvalidReserveIndex error from revert data.
func (c *AaveProtocolDataProvider) DecodeInvalidReserveIndexError(data []byte) (*InvalidReserveIndex, error) {
	args := c.ABI.Errors["InvalidReserveIndex"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &InvalidReserveIndex{}, nil
}

// Error implements the error interface for InvalidReserveIndex.
func (e *InvalidReserveIndex) Error() string {
	return fmt.Sprintf("InvalidReserveIndex error:")
}

// DecodeZeroAddressNotValidError decodes a ZeroAddressNotValid error from revert data.
func (c *AaveProtocolDataProvider) DecodeZeroAddressNotValidError(data []byte) (*ZeroAddressNotValid, error) {
	args := c.ABI.Errors["ZeroAddressNotValid"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ZeroAddressNotValid{}, nil
}

// Error implements the error interface for ZeroAddressNotValid.
func (e *ZeroAddressNotValid) Error() string {
	return fmt.Sprintf("ZeroAddressNotValid error:")
}

func (c *AaveProtocolDataProvider) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	case common.Bytes2Hex(c.ABI.Errors["InvalidReserveIndex"].ID.Bytes()[:4]):
		return c.DecodeInvalidReserveIndexError(data)
	case common.Bytes2Hex(c.ABI.Errors["ZeroAddressNotValid"].ID.Bytes()[:4]):
		return c.DecodeZeroAddressNotValidError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}
