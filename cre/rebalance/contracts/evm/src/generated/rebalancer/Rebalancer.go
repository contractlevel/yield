// Code generated — DO NOT EDIT.

package rebalancer

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

var RebalancerMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"acceptOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getCurrentStrategy\",\"inputs\":[],\"outputs\":[{\"name\":\"currentStrategy\",\"type\":\"tuple\",\"internalType\":\"structIYieldPeer.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getKeystoneForwarder\",\"inputs\":[],\"outputs\":[{\"name\":\"keystoneForwarder\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getParentPeer\",\"inputs\":[],\"outputs\":[{\"name\":\"parentPeer\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getWorkflow\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"workflow\",\"type\":\"tuple\",\"internalType\":\"structCREReceiver.Workflow\",\"components\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"bytes10\",\"internalType\":\"bytes10\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onReport\",\"inputs\":[{\"name\":\"metadata\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"report\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeWorkflow\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setKeystoneForwarder\",\"inputs\":[{\"name\":\"keystoneForwarder\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setParentPeer\",\"inputs\":[{\"name\":\"parentPeer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyRegistry\",\"inputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setWorkflow\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"workflowOwner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"workflowName\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"InvalidChainSelectorInReport\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InvalidProtocolIdInReport\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"KeystoneForwarderSet\",\"inputs\":[{\"name\":\"keystoneForwarder\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OnReportSecurityChecksPassed\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"workflowOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"workflowName\",\"type\":\"bytes10\",\"indexed\":true,\"internalType\":\"bytes10\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferStarted\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ParentPeerSet\",\"inputs\":[{\"name\":\"parentPeer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ReportDecoded\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyRegistrySet\",\"inputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WorkflowRemoved\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"workflowOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"workflowName\",\"type\":\"bytes10\",\"indexed\":true,\"internalType\":\"bytes10\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WorkflowSet\",\"inputs\":[{\"name\":\"workflowId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"workflowOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"workflowName\",\"type\":\"bytes10\",\"indexed\":true,\"internalType\":\"bytes10\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"CREReceiver__InvalidKeystoneForwarder\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expectedForwarder\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"CREReceiver__InvalidWorkflow\",\"inputs\":[{\"name\":\"receivedId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receivedOwner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receivedName\",\"type\":\"bytes10\",\"internalType\":\"bytes10\"}]},{\"type\":\"error\",\"name\":\"CREReceiver__NotEmptyName\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CREReceiver__NotZeroAddress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CREReceiver__NotZeroId\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"Rebalancer__NotZeroAddress\",\"inputs\":[]}]",
}

// Structs
type CREReceiverWorkflow struct {
	Owner common.Address
	Name  [10]byte
}

type IYieldPeerStrategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

// Contract Method Inputs
type GetWorkflowInput struct {
	WorkflowId [32]byte
}

type OnReportInput struct {
	Metadata []byte
	Report   []byte
}

type RemoveWorkflowInput struct {
	WorkflowId [32]byte
}

type SetKeystoneForwarderInput struct {
	KeystoneForwarder common.Address
}

type SetParentPeerInput struct {
	ParentPeer common.Address
}

type SetStrategyRegistryInput struct {
	StrategyRegistry common.Address
}

type SetWorkflowInput struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  string
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type TransferOwnershipInput struct {
	NewOwner common.Address
}

// Contract Method Outputs

// Errors
type CREReceiverInvalidKeystoneForwarder struct {
	Sender            common.Address
	ExpectedForwarder common.Address
}

type CREReceiverInvalidWorkflow struct {
	ReceivedId    [32]byte
	ReceivedOwner common.Address
	ReceivedName  [10]byte
}

type CREReceiverNotEmptyName struct {
}

type CREReceiverNotZeroAddress struct {
}

type CREReceiverNotZeroId struct {
}

type OwnableInvalidOwner struct {
	Owner common.Address
}

type OwnableUnauthorizedAccount struct {
	Account common.Address
}

type RebalancerNotZeroAddress struct {
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

type InvalidChainSelectorInReportTopics struct {
	ChainSelector uint64
}

type InvalidChainSelectorInReportDecoded struct {
	ChainSelector uint64
}

type InvalidProtocolIdInReportTopics struct {
	ProtocolId [32]byte
}

type InvalidProtocolIdInReportDecoded struct {
	ProtocolId [32]byte
}

type KeystoneForwarderSetTopics struct {
	KeystoneForwarder common.Address
}

type KeystoneForwarderSetDecoded struct {
	KeystoneForwarder common.Address
}

type OnReportSecurityChecksPassedTopics struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

type OnReportSecurityChecksPassedDecoded struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

type OwnershipTransferStartedTopics struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferStartedDecoded struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferredTopics struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferredDecoded struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type ParentPeerSetTopics struct {
	ParentPeer common.Address
}

type ParentPeerSetDecoded struct {
	ParentPeer common.Address
}

type ReportDecodedTopics struct {
	ChainSelector uint64
	ProtocolId    [32]byte
}

type ReportDecodedDecoded struct {
	ChainSelector uint64
	ProtocolId    [32]byte
}

type StrategyRegistrySetTopics struct {
	StrategyRegistry common.Address
}

type StrategyRegistrySetDecoded struct {
	StrategyRegistry common.Address
}

type WorkflowRemovedTopics struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

type WorkflowRemovedDecoded struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

type WorkflowSetTopics struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

type WorkflowSetDecoded struct {
	WorkflowId    [32]byte
	WorkflowOwner common.Address
	WorkflowName  [10]byte
}

// Main Binding Type for Rebalancer
type Rebalancer struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   RebalancerCodec
}

type RebalancerCodec interface {
	EncodeAcceptOwnershipMethodCall() ([]byte, error)
	EncodeGetCurrentStrategyMethodCall() ([]byte, error)
	DecodeGetCurrentStrategyMethodOutput(data []byte) (IYieldPeerStrategy, error)
	EncodeGetKeystoneForwarderMethodCall() ([]byte, error)
	DecodeGetKeystoneForwarderMethodOutput(data []byte) (common.Address, error)
	EncodeGetParentPeerMethodCall() ([]byte, error)
	DecodeGetParentPeerMethodOutput(data []byte) (common.Address, error)
	EncodeGetStrategyRegistryMethodCall() ([]byte, error)
	DecodeGetStrategyRegistryMethodOutput(data []byte) (common.Address, error)
	EncodeGetWorkflowMethodCall(in GetWorkflowInput) ([]byte, error)
	DecodeGetWorkflowMethodOutput(data []byte) (CREReceiverWorkflow, error)
	EncodeOnReportMethodCall(in OnReportInput) ([]byte, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodePendingOwnerMethodCall() ([]byte, error)
	DecodePendingOwnerMethodOutput(data []byte) (common.Address, error)
	EncodeRemoveWorkflowMethodCall(in RemoveWorkflowInput) ([]byte, error)
	EncodeRenounceOwnershipMethodCall() ([]byte, error)
	EncodeSetKeystoneForwarderMethodCall(in SetKeystoneForwarderInput) ([]byte, error)
	EncodeSetParentPeerMethodCall(in SetParentPeerInput) ([]byte, error)
	EncodeSetStrategyRegistryMethodCall(in SetStrategyRegistryInput) ([]byte, error)
	EncodeSetWorkflowMethodCall(in SetWorkflowInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error)
	EncodeCREReceiverWorkflowStruct(in CREReceiverWorkflow) ([]byte, error)
	EncodeIYieldPeerStrategyStruct(in IYieldPeerStrategy) ([]byte, error)
	InvalidChainSelectorInReportLogHash() []byte
	EncodeInvalidChainSelectorInReportTopics(evt abi.Event, values []InvalidChainSelectorInReportTopics) ([]*evm.TopicValues, error)
	DecodeInvalidChainSelectorInReport(log *evm.Log) (*InvalidChainSelectorInReportDecoded, error)
	InvalidProtocolIdInReportLogHash() []byte
	EncodeInvalidProtocolIdInReportTopics(evt abi.Event, values []InvalidProtocolIdInReportTopics) ([]*evm.TopicValues, error)
	DecodeInvalidProtocolIdInReport(log *evm.Log) (*InvalidProtocolIdInReportDecoded, error)
	KeystoneForwarderSetLogHash() []byte
	EncodeKeystoneForwarderSetTopics(evt abi.Event, values []KeystoneForwarderSetTopics) ([]*evm.TopicValues, error)
	DecodeKeystoneForwarderSet(log *evm.Log) (*KeystoneForwarderSetDecoded, error)
	OnReportSecurityChecksPassedLogHash() []byte
	EncodeOnReportSecurityChecksPassedTopics(evt abi.Event, values []OnReportSecurityChecksPassedTopics) ([]*evm.TopicValues, error)
	DecodeOnReportSecurityChecksPassed(log *evm.Log) (*OnReportSecurityChecksPassedDecoded, error)
	OwnershipTransferStartedLogHash() []byte
	EncodeOwnershipTransferStartedTopics(evt abi.Event, values []OwnershipTransferStartedTopics) ([]*evm.TopicValues, error)
	DecodeOwnershipTransferStarted(log *evm.Log) (*OwnershipTransferStartedDecoded, error)
	OwnershipTransferredLogHash() []byte
	EncodeOwnershipTransferredTopics(evt abi.Event, values []OwnershipTransferredTopics) ([]*evm.TopicValues, error)
	DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error)
	ParentPeerSetLogHash() []byte
	EncodeParentPeerSetTopics(evt abi.Event, values []ParentPeerSetTopics) ([]*evm.TopicValues, error)
	DecodeParentPeerSet(log *evm.Log) (*ParentPeerSetDecoded, error)
	ReportDecodedLogHash() []byte
	EncodeReportDecodedTopics(evt abi.Event, values []ReportDecodedTopics) ([]*evm.TopicValues, error)
	DecodeReportDecoded(log *evm.Log) (*ReportDecodedDecoded, error)
	StrategyRegistrySetLogHash() []byte
	EncodeStrategyRegistrySetTopics(evt abi.Event, values []StrategyRegistrySetTopics) ([]*evm.TopicValues, error)
	DecodeStrategyRegistrySet(log *evm.Log) (*StrategyRegistrySetDecoded, error)
	WorkflowRemovedLogHash() []byte
	EncodeWorkflowRemovedTopics(evt abi.Event, values []WorkflowRemovedTopics) ([]*evm.TopicValues, error)
	DecodeWorkflowRemoved(log *evm.Log) (*WorkflowRemovedDecoded, error)
	WorkflowSetLogHash() []byte
	EncodeWorkflowSetTopics(evt abi.Event, values []WorkflowSetTopics) ([]*evm.TopicValues, error)
	DecodeWorkflowSet(log *evm.Log) (*WorkflowSetDecoded, error)
}

func NewRebalancer(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*Rebalancer, error) {
	parsed, err := abi.JSON(strings.NewReader(RebalancerMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &Rebalancer{
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

func NewCodec() (RebalancerCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(RebalancerMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeAcceptOwnershipMethodCall() ([]byte, error) {
	return c.abi.Pack("acceptOwnership")
}

func (c *Codec) EncodeGetCurrentStrategyMethodCall() ([]byte, error) {
	return c.abi.Pack("getCurrentStrategy")
}

func (c *Codec) DecodeGetCurrentStrategyMethodOutput(data []byte) (IYieldPeerStrategy, error) {
	vals, err := c.abi.Methods["getCurrentStrategy"].Outputs.Unpack(data)
	if err != nil {
		return *new(IYieldPeerStrategy), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(IYieldPeerStrategy), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result IYieldPeerStrategy
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(IYieldPeerStrategy), fmt.Errorf("failed to unmarshal to IYieldPeerStrategy: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetKeystoneForwarderMethodCall() ([]byte, error) {
	return c.abi.Pack("getKeystoneForwarder")
}

func (c *Codec) DecodeGetKeystoneForwarderMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getKeystoneForwarder"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetParentPeerMethodCall() ([]byte, error) {
	return c.abi.Pack("getParentPeer")
}

func (c *Codec) DecodeGetParentPeerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getParentPeer"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetStrategyRegistryMethodCall() ([]byte, error) {
	return c.abi.Pack("getStrategyRegistry")
}

func (c *Codec) DecodeGetStrategyRegistryMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getStrategyRegistry"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetWorkflowMethodCall(in GetWorkflowInput) ([]byte, error) {
	return c.abi.Pack("getWorkflow", in.WorkflowId)
}

func (c *Codec) DecodeGetWorkflowMethodOutput(data []byte) (CREReceiverWorkflow, error) {
	vals, err := c.abi.Methods["getWorkflow"].Outputs.Unpack(data)
	if err != nil {
		return *new(CREReceiverWorkflow), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(CREReceiverWorkflow), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result CREReceiverWorkflow
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(CREReceiverWorkflow), fmt.Errorf("failed to unmarshal to CREReceiverWorkflow: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeOnReportMethodCall(in OnReportInput) ([]byte, error) {
	return c.abi.Pack("onReport", in.Metadata, in.Report)
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

func (c *Codec) EncodePendingOwnerMethodCall() ([]byte, error) {
	return c.abi.Pack("pendingOwner")
}

func (c *Codec) DecodePendingOwnerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["pendingOwner"].Outputs.Unpack(data)
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

func (c *Codec) EncodeRemoveWorkflowMethodCall(in RemoveWorkflowInput) ([]byte, error) {
	return c.abi.Pack("removeWorkflow", in.WorkflowId)
}

func (c *Codec) EncodeRenounceOwnershipMethodCall() ([]byte, error) {
	return c.abi.Pack("renounceOwnership")
}

func (c *Codec) EncodeSetKeystoneForwarderMethodCall(in SetKeystoneForwarderInput) ([]byte, error) {
	return c.abi.Pack("setKeystoneForwarder", in.KeystoneForwarder)
}

func (c *Codec) EncodeSetParentPeerMethodCall(in SetParentPeerInput) ([]byte, error) {
	return c.abi.Pack("setParentPeer", in.ParentPeer)
}

func (c *Codec) EncodeSetStrategyRegistryMethodCall(in SetStrategyRegistryInput) ([]byte, error) {
	return c.abi.Pack("setStrategyRegistry", in.StrategyRegistry)
}

func (c *Codec) EncodeSetWorkflowMethodCall(in SetWorkflowInput) ([]byte, error) {
	return c.abi.Pack("setWorkflow", in.WorkflowId, in.WorkflowOwner, in.WorkflowName)
}

func (c *Codec) EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error) {
	return c.abi.Pack("supportsInterface", in.InterfaceId)
}

func (c *Codec) DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["supportsInterface"].Outputs.Unpack(data)
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

func (c *Codec) EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error) {
	return c.abi.Pack("transferOwnership", in.NewOwner)
}

func (c *Codec) EncodeCREReceiverWorkflowStruct(in CREReceiverWorkflow) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "owner", Type: "address"},
			{Name: "name", Type: "bytes10"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for CREReceiverWorkflow: %w", err)
	}
	args := abi.Arguments{
		{Name: "cREReceiverWorkflow", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeIYieldPeerStrategyStruct(in IYieldPeerStrategy) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "protocolId", Type: "bytes32"},
			{Name: "chainSelector", Type: "uint64"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for IYieldPeerStrategy: %w", err)
	}
	args := abi.Arguments{
		{Name: "iYieldPeerStrategy", Type: tupleType},
	}

	return args.Pack(in)
}

func (c *Codec) InvalidChainSelectorInReportLogHash() []byte {
	return c.abi.Events["InvalidChainSelectorInReport"].ID.Bytes()
}

func (c *Codec) EncodeInvalidChainSelectorInReportTopics(
	evt abi.Event,
	values []InvalidChainSelectorInReportTopics,
) ([]*evm.TopicValues, error) {
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeInvalidChainSelectorInReport decodes a log into a InvalidChainSelectorInReport struct.
func (c *Codec) DecodeInvalidChainSelectorInReport(log *evm.Log) (*InvalidChainSelectorInReportDecoded, error) {
	event := new(InvalidChainSelectorInReportDecoded)
	if err := c.abi.UnpackIntoInterface(event, "InvalidChainSelectorInReport", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["InvalidChainSelectorInReport"].Inputs {
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

func (c *Codec) InvalidProtocolIdInReportLogHash() []byte {
	return c.abi.Events["InvalidProtocolIdInReport"].ID.Bytes()
}

func (c *Codec) EncodeInvalidProtocolIdInReportTopics(
	evt abi.Event,
	values []InvalidProtocolIdInReportTopics,
) ([]*evm.TopicValues, error) {
	var protocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProtocolId).IsZero() {
			protocolIdRule = append(protocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ProtocolId)
		if err != nil {
			return nil, err
		}
		protocolIdRule = append(protocolIdRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		protocolIdRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeInvalidProtocolIdInReport decodes a log into a InvalidProtocolIdInReport struct.
func (c *Codec) DecodeInvalidProtocolIdInReport(log *evm.Log) (*InvalidProtocolIdInReportDecoded, error) {
	event := new(InvalidProtocolIdInReportDecoded)
	if err := c.abi.UnpackIntoInterface(event, "InvalidProtocolIdInReport", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["InvalidProtocolIdInReport"].Inputs {
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

func (c *Codec) KeystoneForwarderSetLogHash() []byte {
	return c.abi.Events["KeystoneForwarderSet"].ID.Bytes()
}

func (c *Codec) EncodeKeystoneForwarderSetTopics(
	evt abi.Event,
	values []KeystoneForwarderSetTopics,
) ([]*evm.TopicValues, error) {
	var keystoneForwarderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.KeystoneForwarder).IsZero() {
			keystoneForwarderRule = append(keystoneForwarderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.KeystoneForwarder)
		if err != nil {
			return nil, err
		}
		keystoneForwarderRule = append(keystoneForwarderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		keystoneForwarderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeKeystoneForwarderSet decodes a log into a KeystoneForwarderSet struct.
func (c *Codec) DecodeKeystoneForwarderSet(log *evm.Log) (*KeystoneForwarderSetDecoded, error) {
	event := new(KeystoneForwarderSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "KeystoneForwarderSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["KeystoneForwarderSet"].Inputs {
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

func (c *Codec) OnReportSecurityChecksPassedLogHash() []byte {
	return c.abi.Events["OnReportSecurityChecksPassed"].ID.Bytes()
}

func (c *Codec) EncodeOnReportSecurityChecksPassedTopics(
	evt abi.Event,
	values []OnReportSecurityChecksPassedTopics,
) ([]*evm.TopicValues, error) {
	var workflowIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowId).IsZero() {
			workflowIdRule = append(workflowIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.WorkflowId)
		if err != nil {
			return nil, err
		}
		workflowIdRule = append(workflowIdRule, fieldVal)
	}
	var workflowOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowOwner).IsZero() {
			workflowOwnerRule = append(workflowOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.WorkflowOwner)
		if err != nil {
			return nil, err
		}
		workflowOwnerRule = append(workflowOwnerRule, fieldVal)
	}
	var workflowNameRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowName).IsZero() {
			workflowNameRule = append(workflowNameRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.WorkflowName)
		if err != nil {
			return nil, err
		}
		workflowNameRule = append(workflowNameRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		workflowIdRule,
		workflowOwnerRule,
		workflowNameRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeOnReportSecurityChecksPassed decodes a log into a OnReportSecurityChecksPassed struct.
func (c *Codec) DecodeOnReportSecurityChecksPassed(log *evm.Log) (*OnReportSecurityChecksPassedDecoded, error) {
	event := new(OnReportSecurityChecksPassedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "OnReportSecurityChecksPassed", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["OnReportSecurityChecksPassed"].Inputs {
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

func (c *Codec) OwnershipTransferStartedLogHash() []byte {
	return c.abi.Events["OwnershipTransferStarted"].ID.Bytes()
}

func (c *Codec) EncodeOwnershipTransferStartedTopics(
	evt abi.Event,
	values []OwnershipTransferStartedTopics,
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

// DecodeOwnershipTransferStarted decodes a log into a OwnershipTransferStarted struct.
func (c *Codec) DecodeOwnershipTransferStarted(log *evm.Log) (*OwnershipTransferStartedDecoded, error) {
	event := new(OwnershipTransferStartedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "OwnershipTransferStarted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["OwnershipTransferStarted"].Inputs {
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

func (c *Codec) ParentPeerSetLogHash() []byte {
	return c.abi.Events["ParentPeerSet"].ID.Bytes()
}

func (c *Codec) EncodeParentPeerSetTopics(
	evt abi.Event,
	values []ParentPeerSetTopics,
) ([]*evm.TopicValues, error) {
	var parentPeerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ParentPeer).IsZero() {
			parentPeerRule = append(parentPeerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ParentPeer)
		if err != nil {
			return nil, err
		}
		parentPeerRule = append(parentPeerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		parentPeerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeParentPeerSet decodes a log into a ParentPeerSet struct.
func (c *Codec) DecodeParentPeerSet(log *evm.Log) (*ParentPeerSetDecoded, error) {
	event := new(ParentPeerSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ParentPeerSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ParentPeerSet"].Inputs {
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

func (c *Codec) ReportDecodedLogHash() []byte {
	return c.abi.Events["ReportDecoded"].ID.Bytes()
}

func (c *Codec) EncodeReportDecodedTopics(
	evt abi.Event,
	values []ReportDecodedTopics,
) ([]*evm.TopicValues, error) {
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var protocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProtocolId).IsZero() {
			protocolIdRule = append(protocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ProtocolId)
		if err != nil {
			return nil, err
		}
		protocolIdRule = append(protocolIdRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		protocolIdRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeReportDecoded decodes a log into a ReportDecoded struct.
func (c *Codec) DecodeReportDecoded(log *evm.Log) (*ReportDecodedDecoded, error) {
	event := new(ReportDecodedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ReportDecoded", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ReportDecoded"].Inputs {
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

func (c *Codec) StrategyRegistrySetLogHash() []byte {
	return c.abi.Events["StrategyRegistrySet"].ID.Bytes()
}

func (c *Codec) EncodeStrategyRegistrySetTopics(
	evt abi.Event,
	values []StrategyRegistrySetTopics,
) ([]*evm.TopicValues, error) {
	var strategyRegistryRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.StrategyRegistry).IsZero() {
			strategyRegistryRule = append(strategyRegistryRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.StrategyRegistry)
		if err != nil {
			return nil, err
		}
		strategyRegistryRule = append(strategyRegistryRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		strategyRegistryRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeStrategyRegistrySet decodes a log into a StrategyRegistrySet struct.
func (c *Codec) DecodeStrategyRegistrySet(log *evm.Log) (*StrategyRegistrySetDecoded, error) {
	event := new(StrategyRegistrySetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "StrategyRegistrySet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["StrategyRegistrySet"].Inputs {
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

func (c *Codec) WorkflowRemovedLogHash() []byte {
	return c.abi.Events["WorkflowRemoved"].ID.Bytes()
}

func (c *Codec) EncodeWorkflowRemovedTopics(
	evt abi.Event,
	values []WorkflowRemovedTopics,
) ([]*evm.TopicValues, error) {
	var workflowIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowId).IsZero() {
			workflowIdRule = append(workflowIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.WorkflowId)
		if err != nil {
			return nil, err
		}
		workflowIdRule = append(workflowIdRule, fieldVal)
	}
	var workflowOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowOwner).IsZero() {
			workflowOwnerRule = append(workflowOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.WorkflowOwner)
		if err != nil {
			return nil, err
		}
		workflowOwnerRule = append(workflowOwnerRule, fieldVal)
	}
	var workflowNameRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowName).IsZero() {
			workflowNameRule = append(workflowNameRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.WorkflowName)
		if err != nil {
			return nil, err
		}
		workflowNameRule = append(workflowNameRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		workflowIdRule,
		workflowOwnerRule,
		workflowNameRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWorkflowRemoved decodes a log into a WorkflowRemoved struct.
func (c *Codec) DecodeWorkflowRemoved(log *evm.Log) (*WorkflowRemovedDecoded, error) {
	event := new(WorkflowRemovedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WorkflowRemoved", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WorkflowRemoved"].Inputs {
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

func (c *Codec) WorkflowSetLogHash() []byte {
	return c.abi.Events["WorkflowSet"].ID.Bytes()
}

func (c *Codec) EncodeWorkflowSetTopics(
	evt abi.Event,
	values []WorkflowSetTopics,
) ([]*evm.TopicValues, error) {
	var workflowIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowId).IsZero() {
			workflowIdRule = append(workflowIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.WorkflowId)
		if err != nil {
			return nil, err
		}
		workflowIdRule = append(workflowIdRule, fieldVal)
	}
	var workflowOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowOwner).IsZero() {
			workflowOwnerRule = append(workflowOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.WorkflowOwner)
		if err != nil {
			return nil, err
		}
		workflowOwnerRule = append(workflowOwnerRule, fieldVal)
	}
	var workflowNameRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.WorkflowName).IsZero() {
			workflowNameRule = append(workflowNameRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.WorkflowName)
		if err != nil {
			return nil, err
		}
		workflowNameRule = append(workflowNameRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		workflowIdRule,
		workflowOwnerRule,
		workflowNameRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWorkflowSet decodes a log into a WorkflowSet struct.
func (c *Codec) DecodeWorkflowSet(log *evm.Log) (*WorkflowSetDecoded, error) {
	event := new(WorkflowSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WorkflowSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WorkflowSet"].Inputs {
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

func (c Rebalancer) GetCurrentStrategy(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[IYieldPeerStrategy] {
	calldata, err := c.Codec.EncodeGetCurrentStrategyMethodCall()
	if err != nil {
		return cre.PromiseFromResult[IYieldPeerStrategy](*new(IYieldPeerStrategy), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (IYieldPeerStrategy, error) {
		return c.Codec.DecodeGetCurrentStrategyMethodOutput(response.Data)
	})

}

func (c Rebalancer) GetKeystoneForwarder(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetKeystoneForwarderMethodCall()
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
		return c.Codec.DecodeGetKeystoneForwarderMethodOutput(response.Data)
	})

}

func (c Rebalancer) GetParentPeer(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetParentPeerMethodCall()
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
		return c.Codec.DecodeGetParentPeerMethodOutput(response.Data)
	})

}

func (c Rebalancer) GetStrategyRegistry(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetStrategyRegistryMethodCall()
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
		return c.Codec.DecodeGetStrategyRegistryMethodOutput(response.Data)
	})

}

func (c Rebalancer) GetWorkflow(
	runtime cre.Runtime,
	args GetWorkflowInput,
	blockNumber *big.Int,
) cre.Promise[CREReceiverWorkflow] {
	calldata, err := c.Codec.EncodeGetWorkflowMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[CREReceiverWorkflow](*new(CREReceiverWorkflow), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (CREReceiverWorkflow, error) {
		return c.Codec.DecodeGetWorkflowMethodOutput(response.Data)
	})

}

func (c Rebalancer) Owner(
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

func (c Rebalancer) PendingOwner(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodePendingOwnerMethodCall()
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
		return c.Codec.DecodePendingOwnerMethodOutput(response.Data)
	})

}

func (c Rebalancer) WriteReportFromCREReceiverWorkflow(
	runtime cre.Runtime,
	input CREReceiverWorkflow,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeCREReceiverWorkflowStruct(input)
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

func (c Rebalancer) WriteReportFromIYieldPeerStrategy(
	runtime cre.Runtime,
	input IYieldPeerStrategy,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeIYieldPeerStrategyStruct(input)
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

func (c Rebalancer) WriteReport(
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

// DecodeCREReceiverInvalidKeystoneForwarderError decodes a CREReceiver__InvalidKeystoneForwarder error from revert data.
func (c *Rebalancer) DecodeCREReceiverInvalidKeystoneForwarderError(data []byte) (*CREReceiverInvalidKeystoneForwarder, error) {
	args := c.ABI.Errors["CREReceiver__InvalidKeystoneForwarder"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	sender, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for sender in CREReceiverInvalidKeystoneForwarder error")
	}

	expectedForwarder, ok1 := values[1].(common.Address)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for expectedForwarder in CREReceiverInvalidKeystoneForwarder error")
	}

	return &CREReceiverInvalidKeystoneForwarder{
		Sender:            sender,
		ExpectedForwarder: expectedForwarder,
	}, nil
}

// Error implements the error interface for CREReceiverInvalidKeystoneForwarder.
func (e *CREReceiverInvalidKeystoneForwarder) Error() string {
	return fmt.Sprintf("CREReceiverInvalidKeystoneForwarder error: sender=%v; expectedForwarder=%v;", e.Sender, e.ExpectedForwarder)
}

// DecodeCREReceiverInvalidWorkflowError decodes a CREReceiver__InvalidWorkflow error from revert data.
func (c *Rebalancer) DecodeCREReceiverInvalidWorkflowError(data []byte) (*CREReceiverInvalidWorkflow, error) {
	args := c.ABI.Errors["CREReceiver__InvalidWorkflow"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 3 {
		return nil, fmt.Errorf("expected 3 values, got %d", len(values))
	}

	receivedId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for receivedId in CREReceiverInvalidWorkflow error")
	}

	receivedOwner, ok1 := values[1].(common.Address)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for receivedOwner in CREReceiverInvalidWorkflow error")
	}

	receivedName, ok2 := values[2].([10]byte)
	if !ok2 {
		return nil, fmt.Errorf("unexpected type for receivedName in CREReceiverInvalidWorkflow error")
	}

	return &CREReceiverInvalidWorkflow{
		ReceivedId:    receivedId,
		ReceivedOwner: receivedOwner,
		ReceivedName:  receivedName,
	}, nil
}

// Error implements the error interface for CREReceiverInvalidWorkflow.
func (e *CREReceiverInvalidWorkflow) Error() string {
	return fmt.Sprintf("CREReceiverInvalidWorkflow error: receivedId=%v; receivedOwner=%v; receivedName=%v;", e.ReceivedId, e.ReceivedOwner, e.ReceivedName)
}

// DecodeCREReceiverNotEmptyNameError decodes a CREReceiver__NotEmptyName error from revert data.
func (c *Rebalancer) DecodeCREReceiverNotEmptyNameError(data []byte) (*CREReceiverNotEmptyName, error) {
	args := c.ABI.Errors["CREReceiver__NotEmptyName"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &CREReceiverNotEmptyName{}, nil
}

// Error implements the error interface for CREReceiverNotEmptyName.
func (e *CREReceiverNotEmptyName) Error() string {
	return fmt.Sprintf("CREReceiverNotEmptyName error:")
}

// DecodeCREReceiverNotZeroAddressError decodes a CREReceiver__NotZeroAddress error from revert data.
func (c *Rebalancer) DecodeCREReceiverNotZeroAddressError(data []byte) (*CREReceiverNotZeroAddress, error) {
	args := c.ABI.Errors["CREReceiver__NotZeroAddress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &CREReceiverNotZeroAddress{}, nil
}

// Error implements the error interface for CREReceiverNotZeroAddress.
func (e *CREReceiverNotZeroAddress) Error() string {
	return fmt.Sprintf("CREReceiverNotZeroAddress error:")
}

// DecodeCREReceiverNotZeroIdError decodes a CREReceiver__NotZeroId error from revert data.
func (c *Rebalancer) DecodeCREReceiverNotZeroIdError(data []byte) (*CREReceiverNotZeroId, error) {
	args := c.ABI.Errors["CREReceiver__NotZeroId"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &CREReceiverNotZeroId{}, nil
}

// Error implements the error interface for CREReceiverNotZeroId.
func (e *CREReceiverNotZeroId) Error() string {
	return fmt.Sprintf("CREReceiverNotZeroId error:")
}

// DecodeOwnableInvalidOwnerError decodes a OwnableInvalidOwner error from revert data.
func (c *Rebalancer) DecodeOwnableInvalidOwnerError(data []byte) (*OwnableInvalidOwner, error) {
	args := c.ABI.Errors["OwnableInvalidOwner"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	owner, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for owner in OwnableInvalidOwner error")
	}

	return &OwnableInvalidOwner{
		Owner: owner,
	}, nil
}

// Error implements the error interface for OwnableInvalidOwner.
func (e *OwnableInvalidOwner) Error() string {
	return fmt.Sprintf("OwnableInvalidOwner error: owner=%v;", e.Owner)
}

// DecodeOwnableUnauthorizedAccountError decodes a OwnableUnauthorizedAccount error from revert data.
func (c *Rebalancer) DecodeOwnableUnauthorizedAccountError(data []byte) (*OwnableUnauthorizedAccount, error) {
	args := c.ABI.Errors["OwnableUnauthorizedAccount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	account, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for account in OwnableUnauthorizedAccount error")
	}

	return &OwnableUnauthorizedAccount{
		Account: account,
	}, nil
}

// Error implements the error interface for OwnableUnauthorizedAccount.
func (e *OwnableUnauthorizedAccount) Error() string {
	return fmt.Sprintf("OwnableUnauthorizedAccount error: account=%v;", e.Account)
}

// DecodeRebalancerNotZeroAddressError decodes a Rebalancer__NotZeroAddress error from revert data.
func (c *Rebalancer) DecodeRebalancerNotZeroAddressError(data []byte) (*RebalancerNotZeroAddress, error) {
	args := c.ABI.Errors["Rebalancer__NotZeroAddress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &RebalancerNotZeroAddress{}, nil
}

// Error implements the error interface for RebalancerNotZeroAddress.
func (e *RebalancerNotZeroAddress) Error() string {
	return fmt.Sprintf("RebalancerNotZeroAddress error:")
}

func (c *Rebalancer) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	case common.Bytes2Hex(c.ABI.Errors["CREReceiver__InvalidKeystoneForwarder"].ID.Bytes()[:4]):
		return c.DecodeCREReceiverInvalidKeystoneForwarderError(data)
	case common.Bytes2Hex(c.ABI.Errors["CREReceiver__InvalidWorkflow"].ID.Bytes()[:4]):
		return c.DecodeCREReceiverInvalidWorkflowError(data)
	case common.Bytes2Hex(c.ABI.Errors["CREReceiver__NotEmptyName"].ID.Bytes()[:4]):
		return c.DecodeCREReceiverNotEmptyNameError(data)
	case common.Bytes2Hex(c.ABI.Errors["CREReceiver__NotZeroAddress"].ID.Bytes()[:4]):
		return c.DecodeCREReceiverNotZeroAddressError(data)
	case common.Bytes2Hex(c.ABI.Errors["CREReceiver__NotZeroId"].ID.Bytes()[:4]):
		return c.DecodeCREReceiverNotZeroIdError(data)
	case common.Bytes2Hex(c.ABI.Errors["OwnableInvalidOwner"].ID.Bytes()[:4]):
		return c.DecodeOwnableInvalidOwnerError(data)
	case common.Bytes2Hex(c.ABI.Errors["OwnableUnauthorizedAccount"].ID.Bytes()[:4]):
		return c.DecodeOwnableUnauthorizedAccountError(data)
	case common.Bytes2Hex(c.ABI.Errors["Rebalancer__NotZeroAddress"].ID.Bytes()[:4]):
		return c.DecodeRebalancerNotZeroAddressError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}

// InvalidChainSelectorInReportTrigger wraps the raw log trigger and provides decoded InvalidChainSelectorInReportDecoded data
type InvalidChainSelectorInReportTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into InvalidChainSelectorInReport data
func (t *InvalidChainSelectorInReportTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[InvalidChainSelectorInReportDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeInvalidChainSelectorInReport(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode InvalidChainSelectorInReport log: %w", err)
	}

	return &bindings.DecodedLog[InvalidChainSelectorInReportDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerInvalidChainSelectorInReportLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []InvalidChainSelectorInReportTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[InvalidChainSelectorInReportDecoded]], error) {
	event := c.ABI.Events["InvalidChainSelectorInReport"]
	topics, err := c.Codec.EncodeInvalidChainSelectorInReportTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for InvalidChainSelectorInReport: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &InvalidChainSelectorInReportTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsInvalidChainSelectorInReport(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.InvalidChainSelectorInReportLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// InvalidProtocolIdInReportTrigger wraps the raw log trigger and provides decoded InvalidProtocolIdInReportDecoded data
type InvalidProtocolIdInReportTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into InvalidProtocolIdInReport data
func (t *InvalidProtocolIdInReportTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[InvalidProtocolIdInReportDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeInvalidProtocolIdInReport(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode InvalidProtocolIdInReport log: %w", err)
	}

	return &bindings.DecodedLog[InvalidProtocolIdInReportDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerInvalidProtocolIdInReportLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []InvalidProtocolIdInReportTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[InvalidProtocolIdInReportDecoded]], error) {
	event := c.ABI.Events["InvalidProtocolIdInReport"]
	topics, err := c.Codec.EncodeInvalidProtocolIdInReportTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for InvalidProtocolIdInReport: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &InvalidProtocolIdInReportTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsInvalidProtocolIdInReport(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.InvalidProtocolIdInReportLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// KeystoneForwarderSetTrigger wraps the raw log trigger and provides decoded KeystoneForwarderSetDecoded data
type KeystoneForwarderSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into KeystoneForwarderSet data
func (t *KeystoneForwarderSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[KeystoneForwarderSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeKeystoneForwarderSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode KeystoneForwarderSet log: %w", err)
	}

	return &bindings.DecodedLog[KeystoneForwarderSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerKeystoneForwarderSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []KeystoneForwarderSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[KeystoneForwarderSetDecoded]], error) {
	event := c.ABI.Events["KeystoneForwarderSet"]
	topics, err := c.Codec.EncodeKeystoneForwarderSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for KeystoneForwarderSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &KeystoneForwarderSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsKeystoneForwarderSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.KeystoneForwarderSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OnReportSecurityChecksPassedTrigger wraps the raw log trigger and provides decoded OnReportSecurityChecksPassedDecoded data
type OnReportSecurityChecksPassedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into OnReportSecurityChecksPassed data
func (t *OnReportSecurityChecksPassedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[OnReportSecurityChecksPassedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeOnReportSecurityChecksPassed(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode OnReportSecurityChecksPassed log: %w", err)
	}

	return &bindings.DecodedLog[OnReportSecurityChecksPassedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerOnReportSecurityChecksPassedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OnReportSecurityChecksPassedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OnReportSecurityChecksPassedDecoded]], error) {
	event := c.ABI.Events["OnReportSecurityChecksPassed"]
	topics, err := c.Codec.EncodeOnReportSecurityChecksPassedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for OnReportSecurityChecksPassed: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &OnReportSecurityChecksPassedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsOnReportSecurityChecksPassed(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.OnReportSecurityChecksPassedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OwnershipTransferStartedTrigger wraps the raw log trigger and provides decoded OwnershipTransferStartedDecoded data
type OwnershipTransferStartedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into OwnershipTransferStarted data
func (t *OwnershipTransferStartedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[OwnershipTransferStartedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeOwnershipTransferStarted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode OwnershipTransferStarted log: %w", err)
	}

	return &bindings.DecodedLog[OwnershipTransferStartedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerOwnershipTransferStartedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OwnershipTransferStartedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OwnershipTransferStartedDecoded]], error) {
	event := c.ABI.Events["OwnershipTransferStarted"]
	topics, err := c.Codec.EncodeOwnershipTransferStartedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for OwnershipTransferStarted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &OwnershipTransferStartedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsOwnershipTransferStarted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.OwnershipTransferStartedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OwnershipTransferredTrigger wraps the raw log trigger and provides decoded OwnershipTransferredDecoded data
type OwnershipTransferredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
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

func (c *Rebalancer) LogTriggerOwnershipTransferredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OwnershipTransferredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OwnershipTransferredDecoded]], error) {
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

func (c *Rebalancer) FilterLogsOwnershipTransferred(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// ParentPeerSetTrigger wraps the raw log trigger and provides decoded ParentPeerSetDecoded data
type ParentPeerSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into ParentPeerSet data
func (t *ParentPeerSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ParentPeerSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeParentPeerSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ParentPeerSet log: %w", err)
	}

	return &bindings.DecodedLog[ParentPeerSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerParentPeerSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ParentPeerSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ParentPeerSetDecoded]], error) {
	event := c.ABI.Events["ParentPeerSet"]
	topics, err := c.Codec.EncodeParentPeerSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ParentPeerSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ParentPeerSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsParentPeerSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ParentPeerSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ReportDecodedTrigger wraps the raw log trigger and provides decoded ReportDecodedDecoded data
type ReportDecodedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into ReportDecoded data
func (t *ReportDecodedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ReportDecodedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeReportDecoded(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ReportDecoded log: %w", err)
	}

	return &bindings.DecodedLog[ReportDecodedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerReportDecodedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ReportDecodedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ReportDecodedDecoded]], error) {
	event := c.ABI.Events["ReportDecoded"]
	topics, err := c.Codec.EncodeReportDecodedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ReportDecoded: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ReportDecodedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsReportDecoded(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ReportDecodedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// StrategyRegistrySetTrigger wraps the raw log trigger and provides decoded StrategyRegistrySetDecoded data
type StrategyRegistrySetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into StrategyRegistrySet data
func (t *StrategyRegistrySetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[StrategyRegistrySetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeStrategyRegistrySet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode StrategyRegistrySet log: %w", err)
	}

	return &bindings.DecodedLog[StrategyRegistrySetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerStrategyRegistrySetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []StrategyRegistrySetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[StrategyRegistrySetDecoded]], error) {
	event := c.ABI.Events["StrategyRegistrySet"]
	topics, err := c.Codec.EncodeStrategyRegistrySetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for StrategyRegistrySet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &StrategyRegistrySetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsStrategyRegistrySet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.StrategyRegistrySetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WorkflowRemovedTrigger wraps the raw log trigger and provides decoded WorkflowRemovedDecoded data
type WorkflowRemovedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into WorkflowRemoved data
func (t *WorkflowRemovedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WorkflowRemovedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWorkflowRemoved(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WorkflowRemoved log: %w", err)
	}

	return &bindings.DecodedLog[WorkflowRemovedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerWorkflowRemovedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WorkflowRemovedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WorkflowRemovedDecoded]], error) {
	event := c.ABI.Events["WorkflowRemoved"]
	topics, err := c.Codec.EncodeWorkflowRemovedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WorkflowRemoved: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WorkflowRemovedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsWorkflowRemoved(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WorkflowRemovedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WorkflowSetTrigger wraps the raw log trigger and provides decoded WorkflowSetDecoded data
type WorkflowSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *Rebalancer // Keep reference for decoding
}

// Adapt method that decodes the log into WorkflowSet data
func (t *WorkflowSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WorkflowSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWorkflowSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WorkflowSet log: %w", err)
	}

	return &bindings.DecodedLog[WorkflowSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *Rebalancer) LogTriggerWorkflowSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WorkflowSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WorkflowSetDecoded]], error) {
	event := c.ABI.Events["WorkflowSet"]
	topics, err := c.Codec.EncodeWorkflowSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WorkflowSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WorkflowSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *Rebalancer) FilterLogsWorkflowSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WorkflowSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}
