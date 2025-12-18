// Code generated — DO NOT EDIT.

//go:build !wasip1

package aave_protocol_data_provider

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

// AaveProtocolDataProviderMock is a mock implementation of AaveProtocolDataProvider for testing.
type AaveProtocolDataProviderMock struct {
	ADDRESSESPROVIDER              func() (common.Address, error)
	POOL                           func() (common.Address, error)
	GetATokenTotalSupply           func(GetATokenTotalSupplyInput) (*big.Int, error)
	GetAllATokens                  func() ([]IPoolDataProviderTokenData, error)
	GetAllReservesTokens           func() ([]IPoolDataProviderTokenData, error)
	GetDebtCeiling                 func(GetDebtCeilingInput) (*big.Int, error)
	GetFlashLoanEnabled            func(GetFlashLoanEnabledInput) (bool, error)
	GetInterestRateStrategyAddress func(GetInterestRateStrategyAddressInput) (common.Address, error)
	GetLiquidationProtocolFee      func(GetLiquidationProtocolFeeInput) (*big.Int, error)
	GetPaused                      func(GetPausedInput) (bool, error)
	GetReserveCaps                 func(GetReserveCapsInput) (GetReserveCapsOutput, error)
	GetReserveConfigurationData    func(GetReserveConfigurationDataInput) (GetReserveConfigurationDataOutput, error)
	GetReserveData                 func(GetReserveDataInput) (GetReserveDataOutput, error)
	GetReserveDeficit              func(GetReserveDeficitInput) (*big.Int, error)
	GetReserveTokensAddresses      func(GetReserveTokensAddressesInput) (GetReserveTokensAddressesOutput, error)
	GetSiloedBorrowing             func(GetSiloedBorrowingInput) (bool, error)
	GetTotalDebt                   func(GetTotalDebtInput) (*big.Int, error)
	GetUserReserveData             func(GetUserReserveDataInput) (GetUserReserveDataOutput, error)
	GetVirtualUnderlyingBalance    func(GetVirtualUnderlyingBalanceInput) (*big.Int, error)
}

// NewAaveProtocolDataProviderMock creates a new AaveProtocolDataProviderMock for testing.
func NewAaveProtocolDataProviderMock(address common.Address, clientMock *evmmock.ClientCapability) *AaveProtocolDataProviderMock {
	mock := &AaveProtocolDataProviderMock{}

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
		string(abi.Methods["POOL"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.POOL == nil {
				return nil, errors.New("POOL method not mocked")
			}
			result, err := mock.POOL()
			if err != nil {
				return nil, err
			}
			return abi.Methods["POOL"].Outputs.Pack(result)
		},
		string(abi.Methods["getATokenTotalSupply"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetATokenTotalSupply == nil {
				return nil, errors.New("getATokenTotalSupply method not mocked")
			}
			inputs := abi.Methods["getATokenTotalSupply"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetATokenTotalSupplyInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetATokenTotalSupply(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getATokenTotalSupply"].Outputs.Pack(result)
		},
		string(abi.Methods["getAllATokens"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAllATokens == nil {
				return nil, errors.New("getAllATokens method not mocked")
			}
			result, err := mock.GetAllATokens()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAllATokens"].Outputs.Pack(result)
		},
		string(abi.Methods["getAllReservesTokens"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAllReservesTokens == nil {
				return nil, errors.New("getAllReservesTokens method not mocked")
			}
			result, err := mock.GetAllReservesTokens()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAllReservesTokens"].Outputs.Pack(result)
		},
		string(abi.Methods["getDebtCeiling"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetDebtCeiling == nil {
				return nil, errors.New("getDebtCeiling method not mocked")
			}
			inputs := abi.Methods["getDebtCeiling"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetDebtCeilingInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetDebtCeiling(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getDebtCeiling"].Outputs.Pack(result)
		},
		string(abi.Methods["getFlashLoanEnabled"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetFlashLoanEnabled == nil {
				return nil, errors.New("getFlashLoanEnabled method not mocked")
			}
			inputs := abi.Methods["getFlashLoanEnabled"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetFlashLoanEnabledInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetFlashLoanEnabled(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getFlashLoanEnabled"].Outputs.Pack(result)
		},
		string(abi.Methods["getInterestRateStrategyAddress"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetInterestRateStrategyAddress == nil {
				return nil, errors.New("getInterestRateStrategyAddress method not mocked")
			}
			inputs := abi.Methods["getInterestRateStrategyAddress"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetInterestRateStrategyAddressInput{
				Arg0: values[0].(common.Address),
			}

			result, err := mock.GetInterestRateStrategyAddress(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getInterestRateStrategyAddress"].Outputs.Pack(result)
		},
		string(abi.Methods["getLiquidationProtocolFee"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetLiquidationProtocolFee == nil {
				return nil, errors.New("getLiquidationProtocolFee method not mocked")
			}
			inputs := abi.Methods["getLiquidationProtocolFee"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetLiquidationProtocolFeeInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetLiquidationProtocolFee(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getLiquidationProtocolFee"].Outputs.Pack(result)
		},
		string(abi.Methods["getPaused"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPaused == nil {
				return nil, errors.New("getPaused method not mocked")
			}
			inputs := abi.Methods["getPaused"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetPausedInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetPaused(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPaused"].Outputs.Pack(result)
		},
		string(abi.Methods["getReserveCaps"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetReserveCaps == nil {
				return nil, errors.New("getReserveCaps method not mocked")
			}
			inputs := abi.Methods["getReserveCaps"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetReserveCapsInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetReserveCaps(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getReserveCaps"].Outputs.Pack(
				result.BorrowCap,
				result.SupplyCap,
			)
		},
		string(abi.Methods["getReserveConfigurationData"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetReserveConfigurationData == nil {
				return nil, errors.New("getReserveConfigurationData method not mocked")
			}
			inputs := abi.Methods["getReserveConfigurationData"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetReserveConfigurationDataInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetReserveConfigurationData(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getReserveConfigurationData"].Outputs.Pack(
				result.Decimals,
				result.Ltv,
				result.LiquidationThreshold,
				result.LiquidationBonus,
				result.ReserveFactor,
				result.UsageAsCollateralEnabled,
				result.BorrowingEnabled,
				result.StableBorrowRateEnabled,
				result.IsActive,
				result.IsFrozen,
			)
		},
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
				result.Arg0,
				result.AccruedToTreasuryScaled,
				result.TotalAToken,
				result.Arg3,
				result.TotalVariableDebt,
				result.LiquidityRate,
				result.VariableBorrowRate,
				result.Arg7,
				result.Arg8,
				result.LiquidityIndex,
				result.VariableBorrowIndex,
				result.LastUpdateTimestamp,
			)
		},
		string(abi.Methods["getReserveDeficit"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetReserveDeficit == nil {
				return nil, errors.New("getReserveDeficit method not mocked")
			}
			inputs := abi.Methods["getReserveDeficit"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetReserveDeficitInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetReserveDeficit(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getReserveDeficit"].Outputs.Pack(result)
		},
		string(abi.Methods["getReserveTokensAddresses"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetReserveTokensAddresses == nil {
				return nil, errors.New("getReserveTokensAddresses method not mocked")
			}
			inputs := abi.Methods["getReserveTokensAddresses"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetReserveTokensAddressesInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetReserveTokensAddresses(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getReserveTokensAddresses"].Outputs.Pack(
				result.ATokenAddress,
				result.StableDebtTokenAddress,
				result.VariableDebtTokenAddress,
			)
		},
		string(abi.Methods["getSiloedBorrowing"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetSiloedBorrowing == nil {
				return nil, errors.New("getSiloedBorrowing method not mocked")
			}
			inputs := abi.Methods["getSiloedBorrowing"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetSiloedBorrowingInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetSiloedBorrowing(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getSiloedBorrowing"].Outputs.Pack(result)
		},
		string(abi.Methods["getTotalDebt"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetTotalDebt == nil {
				return nil, errors.New("getTotalDebt method not mocked")
			}
			inputs := abi.Methods["getTotalDebt"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetTotalDebtInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetTotalDebt(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getTotalDebt"].Outputs.Pack(result)
		},
		string(abi.Methods["getUserReserveData"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetUserReserveData == nil {
				return nil, errors.New("getUserReserveData method not mocked")
			}
			inputs := abi.Methods["getUserReserveData"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := GetUserReserveDataInput{
				Asset: values[0].(common.Address),
				User:  values[1].(common.Address),
			}

			result, err := mock.GetUserReserveData(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getUserReserveData"].Outputs.Pack(
				result.CurrentATokenBalance,
				result.CurrentStableDebt,
				result.CurrentVariableDebt,
				result.PrincipalStableDebt,
				result.ScaledVariableDebt,
				result.StableBorrowRate,
				result.LiquidityRate,
				result.StableRateLastUpdated,
				result.UsageAsCollateralEnabled,
			)
		},
		string(abi.Methods["getVirtualUnderlyingBalance"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetVirtualUnderlyingBalance == nil {
				return nil, errors.New("getVirtualUnderlyingBalance method not mocked")
			}
			inputs := abi.Methods["getVirtualUnderlyingBalance"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetVirtualUnderlyingBalanceInput{
				Asset: values[0].(common.Address),
			}

			result, err := mock.GetVirtualUnderlyingBalance(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getVirtualUnderlyingBalance"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
