// Code generated — DO NOT EDIT.

package pool_addresses_provider

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

var PoolAddressesProviderMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"string\",\"name\":\"marketId\",\"type\":\"string\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"ACLAdminUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"ACLManagerUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"AddressSet\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"proxyAddress\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"oldImplementationAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newImplementationAddress\",\"type\":\"address\"}],\"name\":\"AddressSetAsProxy\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"string\",\"name\":\"oldMarketId\",\"type\":\"string\"},{\"indexed\":true,\"internalType\":\"string\",\"name\":\"newMarketId\",\"type\":\"string\"}],\"name\":\"MarketIdSet\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"previousOwner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"OwnershipTransferred\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"PoolConfiguratorUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"PoolDataProviderUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"PoolUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"PriceOracleSentinelUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"oldAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"PriceOracleUpdated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"proxyAddress\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"implementationAddress\",\"type\":\"address\"}],\"name\":\"ProxyCreated\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"getACLAdmin\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getACLManager\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"}],\"name\":\"getAddress\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getMarketId\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getPoolConfigurator\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getPoolDataProvider\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getPriceOracle\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getPriceOracleSentinel\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"renounceOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newAclAdmin\",\"type\":\"address\"}],\"name\":\"setACLAdmin\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newAclManager\",\"type\":\"address\"}],\"name\":\"setACLManager\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"},{\"internalType\":\"address\",\"name\":\"newAddress\",\"type\":\"address\"}],\"name\":\"setAddress\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"id\",\"type\":\"bytes32\"},{\"internalType\":\"address\",\"name\":\"newImplementationAddress\",\"type\":\"address\"}],\"name\":\"setAddressAsProxy\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"newMarketId\",\"type\":\"string\"}],\"name\":\"setMarketId\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newPoolConfiguratorImpl\",\"type\":\"address\"}],\"name\":\"setPoolConfiguratorImpl\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newDataProvider\",\"type\":\"address\"}],\"name\":\"setPoolDataProvider\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newPoolImpl\",\"type\":\"address\"}],\"name\":\"setPoolImpl\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newPriceOracle\",\"type\":\"address\"}],\"name\":\"setPriceOracle\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newPriceOracleSentinel\",\"type\":\"address\"}],\"name\":\"setPriceOracleSentinel\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"transferOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// Structs

// Contract Method Inputs
type GetAddressInput struct {
	Id [32]byte
}

type SetACLAdminInput struct {
	NewAclAdmin common.Address
}

type SetACLManagerInput struct {
	NewAclManager common.Address
}

type SetAddressInput struct {
	Id         [32]byte
	NewAddress common.Address
}

type SetAddressAsProxyInput struct {
	Id                       [32]byte
	NewImplementationAddress common.Address
}

type SetMarketIdInput struct {
	NewMarketId string
}

type SetPoolConfiguratorImplInput struct {
	NewPoolConfiguratorImpl common.Address
}

type SetPoolDataProviderInput struct {
	NewDataProvider common.Address
}

type SetPoolImplInput struct {
	NewPoolImpl common.Address
}

type SetPriceOracleInput struct {
	NewPriceOracle common.Address
}

type SetPriceOracleSentinelInput struct {
	NewPriceOracleSentinel common.Address
}

type TransferOwnershipInput struct {
	NewOwner common.Address
}

// Contract Method Outputs

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

type ACLAdminUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type ACLAdminUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type ACLManagerUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type ACLManagerUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type AddressSetTopics struct {
	Id         [32]byte
	OldAddress common.Address
	NewAddress common.Address
}

type AddressSetDecoded struct {
	Id         [32]byte
	OldAddress common.Address
	NewAddress common.Address
}

type AddressSetAsProxyTopics struct {
	Id                       [32]byte
	ProxyAddress             common.Address
	NewImplementationAddress common.Address
}

type AddressSetAsProxyDecoded struct {
	Id                       [32]byte
	ProxyAddress             common.Address
	OldImplementationAddress common.Address
	NewImplementationAddress common.Address
}

type MarketIdSetTopics struct {
	OldMarketId common.Hash
	NewMarketId common.Hash
}

type MarketIdSetDecoded struct {
	OldMarketId common.Hash
	NewMarketId common.Hash
}

type OwnershipTransferredTopics struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferredDecoded struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type PoolConfiguratorUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PoolConfiguratorUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PoolDataProviderUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PoolDataProviderUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PoolUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PoolUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PriceOracleSentinelUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PriceOracleSentinelUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PriceOracleUpdatedTopics struct {
	OldAddress common.Address
	NewAddress common.Address
}

type PriceOracleUpdatedDecoded struct {
	OldAddress common.Address
	NewAddress common.Address
}

type ProxyCreatedTopics struct {
	Id                    [32]byte
	ProxyAddress          common.Address
	ImplementationAddress common.Address
}

type ProxyCreatedDecoded struct {
	Id                    [32]byte
	ProxyAddress          common.Address
	ImplementationAddress common.Address
}

// Main Binding Type for PoolAddressesProvider
type PoolAddressesProvider struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   PoolAddressesProviderCodec
}

type PoolAddressesProviderCodec interface {
	EncodeGetACLAdminMethodCall() ([]byte, error)
	DecodeGetACLAdminMethodOutput(data []byte) (common.Address, error)
	EncodeGetACLManagerMethodCall() ([]byte, error)
	DecodeGetACLManagerMethodOutput(data []byte) (common.Address, error)
	EncodeGetAddressMethodCall(in GetAddressInput) ([]byte, error)
	DecodeGetAddressMethodOutput(data []byte) (common.Address, error)
	EncodeGetMarketIdMethodCall() ([]byte, error)
	DecodeGetMarketIdMethodOutput(data []byte) (string, error)
	EncodeGetPoolMethodCall() ([]byte, error)
	DecodeGetPoolMethodOutput(data []byte) (common.Address, error)
	EncodeGetPoolConfiguratorMethodCall() ([]byte, error)
	DecodeGetPoolConfiguratorMethodOutput(data []byte) (common.Address, error)
	EncodeGetPoolDataProviderMethodCall() ([]byte, error)
	DecodeGetPoolDataProviderMethodOutput(data []byte) (common.Address, error)
	EncodeGetPriceOracleMethodCall() ([]byte, error)
	DecodeGetPriceOracleMethodOutput(data []byte) (common.Address, error)
	EncodeGetPriceOracleSentinelMethodCall() ([]byte, error)
	DecodeGetPriceOracleSentinelMethodOutput(data []byte) (common.Address, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodeRenounceOwnershipMethodCall() ([]byte, error)
	EncodeSetACLAdminMethodCall(in SetACLAdminInput) ([]byte, error)
	EncodeSetACLManagerMethodCall(in SetACLManagerInput) ([]byte, error)
	EncodeSetAddressMethodCall(in SetAddressInput) ([]byte, error)
	EncodeSetAddressAsProxyMethodCall(in SetAddressAsProxyInput) ([]byte, error)
	EncodeSetMarketIdMethodCall(in SetMarketIdInput) ([]byte, error)
	EncodeSetPoolConfiguratorImplMethodCall(in SetPoolConfiguratorImplInput) ([]byte, error)
	EncodeSetPoolDataProviderMethodCall(in SetPoolDataProviderInput) ([]byte, error)
	EncodeSetPoolImplMethodCall(in SetPoolImplInput) ([]byte, error)
	EncodeSetPriceOracleMethodCall(in SetPriceOracleInput) ([]byte, error)
	EncodeSetPriceOracleSentinelMethodCall(in SetPriceOracleSentinelInput) ([]byte, error)
	EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error)
	ACLAdminUpdatedLogHash() []byte
	EncodeACLAdminUpdatedTopics(evt abi.Event, values []ACLAdminUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeACLAdminUpdated(log *evm.Log) (*ACLAdminUpdatedDecoded, error)
	ACLManagerUpdatedLogHash() []byte
	EncodeACLManagerUpdatedTopics(evt abi.Event, values []ACLManagerUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeACLManagerUpdated(log *evm.Log) (*ACLManagerUpdatedDecoded, error)
	AddressSetLogHash() []byte
	EncodeAddressSetTopics(evt abi.Event, values []AddressSetTopics) ([]*evm.TopicValues, error)
	DecodeAddressSet(log *evm.Log) (*AddressSetDecoded, error)
	AddressSetAsProxyLogHash() []byte
	EncodeAddressSetAsProxyTopics(evt abi.Event, values []AddressSetAsProxyTopics) ([]*evm.TopicValues, error)
	DecodeAddressSetAsProxy(log *evm.Log) (*AddressSetAsProxyDecoded, error)
	MarketIdSetLogHash() []byte
	EncodeMarketIdSetTopics(evt abi.Event, values []MarketIdSetTopics) ([]*evm.TopicValues, error)
	DecodeMarketIdSet(log *evm.Log) (*MarketIdSetDecoded, error)
	OwnershipTransferredLogHash() []byte
	EncodeOwnershipTransferredTopics(evt abi.Event, values []OwnershipTransferredTopics) ([]*evm.TopicValues, error)
	DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error)
	PoolConfiguratorUpdatedLogHash() []byte
	EncodePoolConfiguratorUpdatedTopics(evt abi.Event, values []PoolConfiguratorUpdatedTopics) ([]*evm.TopicValues, error)
	DecodePoolConfiguratorUpdated(log *evm.Log) (*PoolConfiguratorUpdatedDecoded, error)
	PoolDataProviderUpdatedLogHash() []byte
	EncodePoolDataProviderUpdatedTopics(evt abi.Event, values []PoolDataProviderUpdatedTopics) ([]*evm.TopicValues, error)
	DecodePoolDataProviderUpdated(log *evm.Log) (*PoolDataProviderUpdatedDecoded, error)
	PoolUpdatedLogHash() []byte
	EncodePoolUpdatedTopics(evt abi.Event, values []PoolUpdatedTopics) ([]*evm.TopicValues, error)
	DecodePoolUpdated(log *evm.Log) (*PoolUpdatedDecoded, error)
	PriceOracleSentinelUpdatedLogHash() []byte
	EncodePriceOracleSentinelUpdatedTopics(evt abi.Event, values []PriceOracleSentinelUpdatedTopics) ([]*evm.TopicValues, error)
	DecodePriceOracleSentinelUpdated(log *evm.Log) (*PriceOracleSentinelUpdatedDecoded, error)
	PriceOracleUpdatedLogHash() []byte
	EncodePriceOracleUpdatedTopics(evt abi.Event, values []PriceOracleUpdatedTopics) ([]*evm.TopicValues, error)
	DecodePriceOracleUpdated(log *evm.Log) (*PriceOracleUpdatedDecoded, error)
	ProxyCreatedLogHash() []byte
	EncodeProxyCreatedTopics(evt abi.Event, values []ProxyCreatedTopics) ([]*evm.TopicValues, error)
	DecodeProxyCreated(log *evm.Log) (*ProxyCreatedDecoded, error)
}

func NewPoolAddressesProvider(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*PoolAddressesProvider, error) {
	parsed, err := abi.JSON(strings.NewReader(PoolAddressesProviderMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &PoolAddressesProvider{
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

func NewCodec() (PoolAddressesProviderCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(PoolAddressesProviderMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeGetACLAdminMethodCall() ([]byte, error) {
	return c.abi.Pack("getACLAdmin")
}

func (c *Codec) DecodeGetACLAdminMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getACLAdmin"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetACLManagerMethodCall() ([]byte, error) {
	return c.abi.Pack("getACLManager")
}

func (c *Codec) DecodeGetACLManagerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getACLManager"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetAddressMethodCall(in GetAddressInput) ([]byte, error) {
	return c.abi.Pack("getAddress", in.Id)
}

func (c *Codec) DecodeGetAddressMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getAddress"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetMarketIdMethodCall() ([]byte, error) {
	return c.abi.Pack("getMarketId")
}

func (c *Codec) DecodeGetMarketIdMethodOutput(data []byte) (string, error) {
	vals, err := c.abi.Methods["getMarketId"].Outputs.Unpack(data)
	if err != nil {
		return *new(string), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(string), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result string
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(string), fmt.Errorf("failed to unmarshal to string: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetPoolMethodCall() ([]byte, error) {
	return c.abi.Pack("getPool")
}

func (c *Codec) DecodeGetPoolMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPool"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetPoolConfiguratorMethodCall() ([]byte, error) {
	return c.abi.Pack("getPoolConfigurator")
}

func (c *Codec) DecodeGetPoolConfiguratorMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPoolConfigurator"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetPoolDataProviderMethodCall() ([]byte, error) {
	return c.abi.Pack("getPoolDataProvider")
}

func (c *Codec) DecodeGetPoolDataProviderMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPoolDataProvider"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetPriceOracleMethodCall() ([]byte, error) {
	return c.abi.Pack("getPriceOracle")
}

func (c *Codec) DecodeGetPriceOracleMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPriceOracle"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetPriceOracleSentinelMethodCall() ([]byte, error) {
	return c.abi.Pack("getPriceOracleSentinel")
}

func (c *Codec) DecodeGetPriceOracleSentinelMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPriceOracleSentinel"].Outputs.Unpack(data)
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

func (c *Codec) EncodeOwnerMethodCall() ([]byte, error) {
	return c.abi.Pack("owner")
}

func (c *Codec) DecodeOwnerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["owner"].Outputs.Unpack(data)
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

func (c *Codec) EncodeRenounceOwnershipMethodCall() ([]byte, error) {
	return c.abi.Pack("renounceOwnership")
}

func (c *Codec) EncodeSetACLAdminMethodCall(in SetACLAdminInput) ([]byte, error) {
	return c.abi.Pack("setACLAdmin", in.NewAclAdmin)
}

func (c *Codec) EncodeSetACLManagerMethodCall(in SetACLManagerInput) ([]byte, error) {
	return c.abi.Pack("setACLManager", in.NewAclManager)
}

func (c *Codec) EncodeSetAddressMethodCall(in SetAddressInput) ([]byte, error) {
	return c.abi.Pack("setAddress", in.Id, in.NewAddress)
}

func (c *Codec) EncodeSetAddressAsProxyMethodCall(in SetAddressAsProxyInput) ([]byte, error) {
	return c.abi.Pack("setAddressAsProxy", in.Id, in.NewImplementationAddress)
}

func (c *Codec) EncodeSetMarketIdMethodCall(in SetMarketIdInput) ([]byte, error) {
	return c.abi.Pack("setMarketId", in.NewMarketId)
}

func (c *Codec) EncodeSetPoolConfiguratorImplMethodCall(in SetPoolConfiguratorImplInput) ([]byte, error) {
	return c.abi.Pack("setPoolConfiguratorImpl", in.NewPoolConfiguratorImpl)
}

func (c *Codec) EncodeSetPoolDataProviderMethodCall(in SetPoolDataProviderInput) ([]byte, error) {
	return c.abi.Pack("setPoolDataProvider", in.NewDataProvider)
}

func (c *Codec) EncodeSetPoolImplMethodCall(in SetPoolImplInput) ([]byte, error) {
	return c.abi.Pack("setPoolImpl", in.NewPoolImpl)
}

func (c *Codec) EncodeSetPriceOracleMethodCall(in SetPriceOracleInput) ([]byte, error) {
	return c.abi.Pack("setPriceOracle", in.NewPriceOracle)
}

func (c *Codec) EncodeSetPriceOracleSentinelMethodCall(in SetPriceOracleSentinelInput) ([]byte, error) {
	return c.abi.Pack("setPriceOracleSentinel", in.NewPriceOracleSentinel)
}

func (c *Codec) EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error) {
	return c.abi.Pack("transferOwnership", in.NewOwner)
}

func (c *Codec) ACLAdminUpdatedLogHash() []byte {
	return c.abi.Events["ACLAdminUpdated"].ID.Bytes()
}

func (c *Codec) EncodeACLAdminUpdatedTopics(
	evt abi.Event,
	values []ACLAdminUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeACLAdminUpdated decodes a log into a ACLAdminUpdated struct.
func (c *Codec) DecodeACLAdminUpdated(log *evm.Log) (*ACLAdminUpdatedDecoded, error) {
	event := new(ACLAdminUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ACLAdminUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ACLAdminUpdated"].Inputs {
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

func (c *Codec) ACLManagerUpdatedLogHash() []byte {
	return c.abi.Events["ACLManagerUpdated"].ID.Bytes()
}

func (c *Codec) EncodeACLManagerUpdatedTopics(
	evt abi.Event,
	values []ACLManagerUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeACLManagerUpdated decodes a log into a ACLManagerUpdated struct.
func (c *Codec) DecodeACLManagerUpdated(log *evm.Log) (*ACLManagerUpdatedDecoded, error) {
	event := new(ACLManagerUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ACLManagerUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ACLManagerUpdated"].Inputs {
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

func (c *Codec) AddressSetLogHash() []byte {
	return c.abi.Events["AddressSet"].ID.Bytes()
}

func (c *Codec) EncodeAddressSetTopics(
	evt abi.Event,
	values []AddressSetTopics,
) ([]*evm.TopicValues, error) {
	var idRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Id).IsZero() {
			idRule = append(idRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Id)
		if err != nil {
			return nil, err
		}
		idRule = append(idRule, fieldVal)
	}
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		idRule,
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeAddressSet decodes a log into a AddressSet struct.
func (c *Codec) DecodeAddressSet(log *evm.Log) (*AddressSetDecoded, error) {
	event := new(AddressSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "AddressSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["AddressSet"].Inputs {
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

func (c *Codec) AddressSetAsProxyLogHash() []byte {
	return c.abi.Events["AddressSetAsProxy"].ID.Bytes()
}

func (c *Codec) EncodeAddressSetAsProxyTopics(
	evt abi.Event,
	values []AddressSetAsProxyTopics,
) ([]*evm.TopicValues, error) {
	var idRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Id).IsZero() {
			idRule = append(idRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Id)
		if err != nil {
			return nil, err
		}
		idRule = append(idRule, fieldVal)
	}
	var proxyAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProxyAddress).IsZero() {
			proxyAddressRule = append(proxyAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ProxyAddress)
		if err != nil {
			return nil, err
		}
		proxyAddressRule = append(proxyAddressRule, fieldVal)
	}
	var newImplementationAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewImplementationAddress).IsZero() {
			newImplementationAddressRule = append(newImplementationAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[3], v.NewImplementationAddress)
		if err != nil {
			return nil, err
		}
		newImplementationAddressRule = append(newImplementationAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		idRule,
		proxyAddressRule,
		newImplementationAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeAddressSetAsProxy decodes a log into a AddressSetAsProxy struct.
func (c *Codec) DecodeAddressSetAsProxy(log *evm.Log) (*AddressSetAsProxyDecoded, error) {
	event := new(AddressSetAsProxyDecoded)
	if err := c.abi.UnpackIntoInterface(event, "AddressSetAsProxy", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["AddressSetAsProxy"].Inputs {
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

func (c *Codec) MarketIdSetLogHash() []byte {
	return c.abi.Events["MarketIdSet"].ID.Bytes()
}

func (c *Codec) EncodeMarketIdSetTopics(
	evt abi.Event,
	values []MarketIdSetTopics,
) ([]*evm.TopicValues, error) {
	var oldMarketIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldMarketId).IsZero() {
			oldMarketIdRule = append(oldMarketIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldMarketId)
		if err != nil {
			return nil, err
		}
		oldMarketIdRule = append(oldMarketIdRule, fieldVal)
	}
	var newMarketIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewMarketId).IsZero() {
			newMarketIdRule = append(newMarketIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewMarketId)
		if err != nil {
			return nil, err
		}
		newMarketIdRule = append(newMarketIdRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldMarketIdRule,
		newMarketIdRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeMarketIdSet decodes a log into a MarketIdSet struct.
func (c *Codec) DecodeMarketIdSet(log *evm.Log) (*MarketIdSetDecoded, error) {
	event := new(MarketIdSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "MarketIdSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["MarketIdSet"].Inputs {
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

func (c *Codec) OwnershipTransferredLogHash() []byte {
	return c.abi.Events["OwnershipTransferred"].ID.Bytes()
}

func (c *Codec) EncodeOwnershipTransferredTopics(
	evt abi.Event,
	values []OwnershipTransferredTopics,
) ([]*evm.TopicValues, error) {
	var previousOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousOwner).IsZero() {
			previousOwnerRule = append(previousOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PreviousOwner)
		if err != nil {
			return nil, err
		}
		previousOwnerRule = append(previousOwnerRule, fieldVal)
	}
	var newOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewOwner).IsZero() {
			newOwnerRule = append(newOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewOwner)
		if err != nil {
			return nil, err
		}
		newOwnerRule = append(newOwnerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		previousOwnerRule,
		newOwnerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeOwnershipTransferred decodes a log into a OwnershipTransferred struct.
func (c *Codec) DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error) {
	event := new(OwnershipTransferredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "OwnershipTransferred", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["OwnershipTransferred"].Inputs {
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

func (c *Codec) PoolConfiguratorUpdatedLogHash() []byte {
	return c.abi.Events["PoolConfiguratorUpdated"].ID.Bytes()
}

func (c *Codec) EncodePoolConfiguratorUpdatedTopics(
	evt abi.Event,
	values []PoolConfiguratorUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePoolConfiguratorUpdated decodes a log into a PoolConfiguratorUpdated struct.
func (c *Codec) DecodePoolConfiguratorUpdated(log *evm.Log) (*PoolConfiguratorUpdatedDecoded, error) {
	event := new(PoolConfiguratorUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PoolConfiguratorUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PoolConfiguratorUpdated"].Inputs {
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

func (c *Codec) PoolDataProviderUpdatedLogHash() []byte {
	return c.abi.Events["PoolDataProviderUpdated"].ID.Bytes()
}

func (c *Codec) EncodePoolDataProviderUpdatedTopics(
	evt abi.Event,
	values []PoolDataProviderUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePoolDataProviderUpdated decodes a log into a PoolDataProviderUpdated struct.
func (c *Codec) DecodePoolDataProviderUpdated(log *evm.Log) (*PoolDataProviderUpdatedDecoded, error) {
	event := new(PoolDataProviderUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PoolDataProviderUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PoolDataProviderUpdated"].Inputs {
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

func (c *Codec) PoolUpdatedLogHash() []byte {
	return c.abi.Events["PoolUpdated"].ID.Bytes()
}

func (c *Codec) EncodePoolUpdatedTopics(
	evt abi.Event,
	values []PoolUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePoolUpdated decodes a log into a PoolUpdated struct.
func (c *Codec) DecodePoolUpdated(log *evm.Log) (*PoolUpdatedDecoded, error) {
	event := new(PoolUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PoolUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PoolUpdated"].Inputs {
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

func (c *Codec) PriceOracleSentinelUpdatedLogHash() []byte {
	return c.abi.Events["PriceOracleSentinelUpdated"].ID.Bytes()
}

func (c *Codec) EncodePriceOracleSentinelUpdatedTopics(
	evt abi.Event,
	values []PriceOracleSentinelUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePriceOracleSentinelUpdated decodes a log into a PriceOracleSentinelUpdated struct.
func (c *Codec) DecodePriceOracleSentinelUpdated(log *evm.Log) (*PriceOracleSentinelUpdatedDecoded, error) {
	event := new(PriceOracleSentinelUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PriceOracleSentinelUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PriceOracleSentinelUpdated"].Inputs {
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

func (c *Codec) PriceOracleUpdatedLogHash() []byte {
	return c.abi.Events["PriceOracleUpdated"].ID.Bytes()
}

func (c *Codec) EncodePriceOracleUpdatedTopics(
	evt abi.Event,
	values []PriceOracleUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var oldAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldAddress).IsZero() {
			oldAddressRule = append(oldAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.OldAddress)
		if err != nil {
			return nil, err
		}
		oldAddressRule = append(oldAddressRule, fieldVal)
	}
	var newAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAddress).IsZero() {
			newAddressRule = append(newAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewAddress)
		if err != nil {
			return nil, err
		}
		newAddressRule = append(newAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		oldAddressRule,
		newAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePriceOracleUpdated decodes a log into a PriceOracleUpdated struct.
func (c *Codec) DecodePriceOracleUpdated(log *evm.Log) (*PriceOracleUpdatedDecoded, error) {
	event := new(PriceOracleUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PriceOracleUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PriceOracleUpdated"].Inputs {
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

func (c *Codec) ProxyCreatedLogHash() []byte {
	return c.abi.Events["ProxyCreated"].ID.Bytes()
}

func (c *Codec) EncodeProxyCreatedTopics(
	evt abi.Event,
	values []ProxyCreatedTopics,
) ([]*evm.TopicValues, error) {
	var idRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Id).IsZero() {
			idRule = append(idRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Id)
		if err != nil {
			return nil, err
		}
		idRule = append(idRule, fieldVal)
	}
	var proxyAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProxyAddress).IsZero() {
			proxyAddressRule = append(proxyAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ProxyAddress)
		if err != nil {
			return nil, err
		}
		proxyAddressRule = append(proxyAddressRule, fieldVal)
	}
	var implementationAddressRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ImplementationAddress).IsZero() {
			implementationAddressRule = append(implementationAddressRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ImplementationAddress)
		if err != nil {
			return nil, err
		}
		implementationAddressRule = append(implementationAddressRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		idRule,
		proxyAddressRule,
		implementationAddressRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeProxyCreated decodes a log into a ProxyCreated struct.
func (c *Codec) DecodeProxyCreated(log *evm.Log) (*ProxyCreatedDecoded, error) {
	event := new(ProxyCreatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ProxyCreated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ProxyCreated"].Inputs {
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

func (c PoolAddressesProvider) GetACLAdmin(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetACLAdminMethodCall()
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
		return c.Codec.DecodeGetACLAdminMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetACLManager(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetACLManagerMethodCall()
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
		return c.Codec.DecodeGetACLManagerMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetAddress(
	runtime cre.Runtime,
	args GetAddressInput,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetAddressMethodCall(args)
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
		return c.Codec.DecodeGetAddressMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetMarketId(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[string] {
	calldata, err := c.Codec.EncodeGetMarketIdMethodCall()
	if err != nil {
		return cre.PromiseFromResult[string](*new(string), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (string, error) {
		return c.Codec.DecodeGetMarketIdMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetPool(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPoolMethodCall()
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
		return c.Codec.DecodeGetPoolMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetPoolConfigurator(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPoolConfiguratorMethodCall()
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
		return c.Codec.DecodeGetPoolConfiguratorMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetPoolDataProvider(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPoolDataProviderMethodCall()
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
		return c.Codec.DecodeGetPoolDataProviderMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetPriceOracle(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPriceOracleMethodCall()
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
		return c.Codec.DecodeGetPriceOracleMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) GetPriceOracleSentinel(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPriceOracleSentinelMethodCall()
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
		return c.Codec.DecodeGetPriceOracleSentinelMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) Owner(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeOwnerMethodCall()
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
		return c.Codec.DecodeOwnerMethodOutput(response.Data)
	})

}

func (c PoolAddressesProvider) WriteReport(
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

func (c *PoolAddressesProvider) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	default:
		return nil, errors.New("unknown error selector")
	}
}

// ACLAdminUpdatedTrigger wraps the raw log trigger and provides decoded ACLAdminUpdatedDecoded data
type ACLAdminUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into ACLAdminUpdated data
func (t *ACLAdminUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ACLAdminUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeACLAdminUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ACLAdminUpdated log: %w", err)
	}

	return &bindings.DecodedLog[ACLAdminUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerACLAdminUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ACLAdminUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ACLAdminUpdatedDecoded]], error) {
	event := c.ABI.Events["ACLAdminUpdated"]
	topics, err := c.Codec.EncodeACLAdminUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ACLAdminUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ACLAdminUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsACLAdminUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ACLAdminUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ACLManagerUpdatedTrigger wraps the raw log trigger and provides decoded ACLManagerUpdatedDecoded data
type ACLManagerUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into ACLManagerUpdated data
func (t *ACLManagerUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ACLManagerUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeACLManagerUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ACLManagerUpdated log: %w", err)
	}

	return &bindings.DecodedLog[ACLManagerUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerACLManagerUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ACLManagerUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ACLManagerUpdatedDecoded]], error) {
	event := c.ABI.Events["ACLManagerUpdated"]
	topics, err := c.Codec.EncodeACLManagerUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ACLManagerUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ACLManagerUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsACLManagerUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ACLManagerUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// AddressSetTrigger wraps the raw log trigger and provides decoded AddressSetDecoded data
type AddressSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into AddressSet data
func (t *AddressSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[AddressSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeAddressSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode AddressSet log: %w", err)
	}

	return &bindings.DecodedLog[AddressSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerAddressSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []AddressSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[AddressSetDecoded]], error) {
	event := c.ABI.Events["AddressSet"]
	topics, err := c.Codec.EncodeAddressSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for AddressSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &AddressSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsAddressSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.AddressSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// AddressSetAsProxyTrigger wraps the raw log trigger and provides decoded AddressSetAsProxyDecoded data
type AddressSetAsProxyTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into AddressSetAsProxy data
func (t *AddressSetAsProxyTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[AddressSetAsProxyDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeAddressSetAsProxy(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode AddressSetAsProxy log: %w", err)
	}

	return &bindings.DecodedLog[AddressSetAsProxyDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerAddressSetAsProxyLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []AddressSetAsProxyTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[AddressSetAsProxyDecoded]], error) {
	event := c.ABI.Events["AddressSetAsProxy"]
	topics, err := c.Codec.EncodeAddressSetAsProxyTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for AddressSetAsProxy: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &AddressSetAsProxyTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsAddressSetAsProxy(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.AddressSetAsProxyLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// MarketIdSetTrigger wraps the raw log trigger and provides decoded MarketIdSetDecoded data
type MarketIdSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into MarketIdSet data
func (t *MarketIdSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[MarketIdSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeMarketIdSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode MarketIdSet log: %w", err)
	}

	return &bindings.DecodedLog[MarketIdSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerMarketIdSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []MarketIdSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[MarketIdSetDecoded]], error) {
	event := c.ABI.Events["MarketIdSet"]
	topics, err := c.Codec.EncodeMarketIdSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for MarketIdSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &MarketIdSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsMarketIdSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.MarketIdSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OwnershipTransferredTrigger wraps the raw log trigger and provides decoded OwnershipTransferredDecoded data
type OwnershipTransferredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into OwnershipTransferred data
func (t *OwnershipTransferredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[OwnershipTransferredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeOwnershipTransferred(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode OwnershipTransferred log: %w", err)
	}

	return &bindings.DecodedLog[OwnershipTransferredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerOwnershipTransferredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OwnershipTransferredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OwnershipTransferredDecoded]], error) {
	event := c.ABI.Events["OwnershipTransferred"]
	topics, err := c.Codec.EncodeOwnershipTransferredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for OwnershipTransferred: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &OwnershipTransferredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsOwnershipTransferred(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.OwnershipTransferredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PoolConfiguratorUpdatedTrigger wraps the raw log trigger and provides decoded PoolConfiguratorUpdatedDecoded data
type PoolConfiguratorUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into PoolConfiguratorUpdated data
func (t *PoolConfiguratorUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PoolConfiguratorUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePoolConfiguratorUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PoolConfiguratorUpdated log: %w", err)
	}

	return &bindings.DecodedLog[PoolConfiguratorUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerPoolConfiguratorUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PoolConfiguratorUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PoolConfiguratorUpdatedDecoded]], error) {
	event := c.ABI.Events["PoolConfiguratorUpdated"]
	topics, err := c.Codec.EncodePoolConfiguratorUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PoolConfiguratorUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PoolConfiguratorUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsPoolConfiguratorUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PoolConfiguratorUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PoolDataProviderUpdatedTrigger wraps the raw log trigger and provides decoded PoolDataProviderUpdatedDecoded data
type PoolDataProviderUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into PoolDataProviderUpdated data
func (t *PoolDataProviderUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PoolDataProviderUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePoolDataProviderUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PoolDataProviderUpdated log: %w", err)
	}

	return &bindings.DecodedLog[PoolDataProviderUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerPoolDataProviderUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PoolDataProviderUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PoolDataProviderUpdatedDecoded]], error) {
	event := c.ABI.Events["PoolDataProviderUpdated"]
	topics, err := c.Codec.EncodePoolDataProviderUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PoolDataProviderUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PoolDataProviderUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsPoolDataProviderUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PoolDataProviderUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PoolUpdatedTrigger wraps the raw log trigger and provides decoded PoolUpdatedDecoded data
type PoolUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into PoolUpdated data
func (t *PoolUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PoolUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePoolUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PoolUpdated log: %w", err)
	}

	return &bindings.DecodedLog[PoolUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerPoolUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PoolUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PoolUpdatedDecoded]], error) {
	event := c.ABI.Events["PoolUpdated"]
	topics, err := c.Codec.EncodePoolUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PoolUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PoolUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsPoolUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PoolUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PriceOracleSentinelUpdatedTrigger wraps the raw log trigger and provides decoded PriceOracleSentinelUpdatedDecoded data
type PriceOracleSentinelUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into PriceOracleSentinelUpdated data
func (t *PriceOracleSentinelUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PriceOracleSentinelUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePriceOracleSentinelUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PriceOracleSentinelUpdated log: %w", err)
	}

	return &bindings.DecodedLog[PriceOracleSentinelUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerPriceOracleSentinelUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PriceOracleSentinelUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PriceOracleSentinelUpdatedDecoded]], error) {
	event := c.ABI.Events["PriceOracleSentinelUpdated"]
	topics, err := c.Codec.EncodePriceOracleSentinelUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PriceOracleSentinelUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PriceOracleSentinelUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsPriceOracleSentinelUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PriceOracleSentinelUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PriceOracleUpdatedTrigger wraps the raw log trigger and provides decoded PriceOracleUpdatedDecoded data
type PriceOracleUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into PriceOracleUpdated data
func (t *PriceOracleUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PriceOracleUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePriceOracleUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PriceOracleUpdated log: %w", err)
	}

	return &bindings.DecodedLog[PriceOracleUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerPriceOracleUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PriceOracleUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PriceOracleUpdatedDecoded]], error) {
	event := c.ABI.Events["PriceOracleUpdated"]
	topics, err := c.Codec.EncodePriceOracleUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PriceOracleUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PriceOracleUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsPriceOracleUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PriceOracleUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ProxyCreatedTrigger wraps the raw log trigger and provides decoded ProxyCreatedDecoded data
type ProxyCreatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                        // Embed the raw trigger
	contract                        *PoolAddressesProvider // Keep reference for decoding
}

// Adapt method that decodes the log into ProxyCreated data
func (t *ProxyCreatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ProxyCreatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeProxyCreated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ProxyCreated log: %w", err)
	}

	return &bindings.DecodedLog[ProxyCreatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *PoolAddressesProvider) LogTriggerProxyCreatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ProxyCreatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ProxyCreatedDecoded]], error) {
	event := c.ABI.Events["ProxyCreated"]
	topics, err := c.Codec.EncodeProxyCreatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ProxyCreated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ProxyCreatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *PoolAddressesProvider) FilterLogsProxyCreated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ProxyCreatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}
