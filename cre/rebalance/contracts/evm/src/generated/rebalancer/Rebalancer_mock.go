// Code generated — DO NOT EDIT.

//go:build !wasip1

package rebalancer

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

// RebalancerMock is a mock implementation of Rebalancer for testing.
type RebalancerMock struct {
	GetCurrentStrategy   func() (IYieldPeerStrategy, error)
	GetKeystoneForwarder func() (common.Address, error)
	GetParentPeer        func() (common.Address, error)
	GetStrategyRegistry  func() (common.Address, error)
	GetWorkflow          func(GetWorkflowInput) (CREReceiverWorkflow, error)
	Owner                func() (common.Address, error)
	PendingOwner         func() (common.Address, error)
}

// NewRebalancerMock creates a new RebalancerMock for testing.
func NewRebalancerMock(address common.Address, clientMock *evmmock.ClientCapability) *RebalancerMock {
	mock := &RebalancerMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["getCurrentStrategy"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCurrentStrategy == nil {
				return nil, errors.New("getCurrentStrategy method not mocked")
			}
			result, err := mock.GetCurrentStrategy()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCurrentStrategy"].Outputs.Pack(result)
		},
		string(abi.Methods["getKeystoneForwarder"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetKeystoneForwarder == nil {
				return nil, errors.New("getKeystoneForwarder method not mocked")
			}
			result, err := mock.GetKeystoneForwarder()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getKeystoneForwarder"].Outputs.Pack(result)
		},
		string(abi.Methods["getParentPeer"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetParentPeer == nil {
				return nil, errors.New("getParentPeer method not mocked")
			}
			result, err := mock.GetParentPeer()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getParentPeer"].Outputs.Pack(result)
		},
		string(abi.Methods["getStrategyRegistry"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetStrategyRegistry == nil {
				return nil, errors.New("getStrategyRegistry method not mocked")
			}
			result, err := mock.GetStrategyRegistry()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getStrategyRegistry"].Outputs.Pack(result)
		},
		string(abi.Methods["getWorkflow"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetWorkflow == nil {
				return nil, errors.New("getWorkflow method not mocked")
			}
			inputs := abi.Methods["getWorkflow"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetWorkflowInput{
				WorkflowId: values[0].([32]byte),
			}

			result, err := mock.GetWorkflow(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getWorkflow"].Outputs.Pack(result)
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
		string(abi.Methods["pendingOwner"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PendingOwner == nil {
				return nil, errors.New("pendingOwner method not mocked")
			}
			result, err := mock.PendingOwner()
			if err != nil {
				return nil, err
			}
			return abi.Methods["pendingOwner"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
