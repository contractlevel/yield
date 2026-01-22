// Code generated — DO NOT EDIT.

//go:build !wasip1

package parent_peer

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

// ParentPeerMock is a mock implementation of ParentPeer for testing.
type ParentPeerMock struct {
	DEFAULTADMINROLE              func() ([32]byte, error)
	DefaultAdmin                  func() (common.Address, error)
	DefaultAdminDelay             func() (*big.Int, error)
	DefaultAdminDelayIncreaseWait func() (*big.Int, error)
	GetActiveStrategyAdapter      func() (common.Address, error)
	GetAllowedChain               func(GetAllowedChainInput) (bool, error)
	GetAllowedPeer                func(GetAllowedPeerInput) (common.Address, error)
	GetCCIPGasLimit               func() (*big.Int, error)
	GetFeeRate                    func() (*big.Int, error)
	GetIsStrategyChain            func() (bool, error)
	GetLink                       func() (common.Address, error)
	GetRebalancer                 func() (common.Address, error)
	GetRoleAdmin                  func(GetRoleAdminInput) ([32]byte, error)
	GetRoleMember                 func(GetRoleMemberInput) (common.Address, error)
	GetRoleMemberCount            func(GetRoleMemberCountInput) (*big.Int, error)
	GetRoleMembers                func(GetRoleMembersInput) ([]common.Address, error)
	GetRouter                     func() (common.Address, error)
	GetShare                      func() (common.Address, error)
	GetStrategy                   func() (IYieldPeerStrategy, error)
	GetStrategyAdapter            func(GetStrategyAdapterInput) (common.Address, error)
	GetStrategyRegistry           func() (common.Address, error)
	GetThisChainSelector          func() (uint64, error)
	GetTotalShares                func() (*big.Int, error)
	GetTotalValue                 func() (*big.Int, error)
	GetUsdc                       func() (common.Address, error)
	HasRole                       func(HasRoleInput) (bool, error)
	Owner                         func() (common.Address, error)
	Paused                        func() (bool, error)
	PendingDefaultAdmin           func() (PendingDefaultAdminOutput, error)
	PendingDefaultAdminDelay      func() (PendingDefaultAdminDelayOutput, error)
	SupportsInterface             func(SupportsInterfaceInput) (bool, error)
}

// NewParentPeerMock creates a new ParentPeerMock for testing.
func NewParentPeerMock(address common.Address, clientMock *evmmock.ClientCapability) *ParentPeerMock {
	mock := &ParentPeerMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["DEFAULT_ADMIN_ROLE"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DEFAULTADMINROLE == nil {
				return nil, errors.New("DEFAULT_ADMIN_ROLE method not mocked")
			}
			result, err := mock.DEFAULTADMINROLE()
			if err != nil {
				return nil, err
			}
			return abi.Methods["DEFAULT_ADMIN_ROLE"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdmin == nil {
				return nil, errors.New("defaultAdmin method not mocked")
			}
			result, err := mock.DefaultAdmin()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdmin"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdminDelay"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdminDelay == nil {
				return nil, errors.New("defaultAdminDelay method not mocked")
			}
			result, err := mock.DefaultAdminDelay()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdminDelay"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdminDelayIncreaseWait"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdminDelayIncreaseWait == nil {
				return nil, errors.New("defaultAdminDelayIncreaseWait method not mocked")
			}
			result, err := mock.DefaultAdminDelayIncreaseWait()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdminDelayIncreaseWait"].Outputs.Pack(result)
		},
		string(abi.Methods["getActiveStrategyAdapter"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetActiveStrategyAdapter == nil {
				return nil, errors.New("getActiveStrategyAdapter method not mocked")
			}
			result, err := mock.GetActiveStrategyAdapter()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getActiveStrategyAdapter"].Outputs.Pack(result)
		},
		string(abi.Methods["getAllowedChain"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAllowedChain == nil {
				return nil, errors.New("getAllowedChain method not mocked")
			}
			inputs := abi.Methods["getAllowedChain"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetAllowedChainInput{
				ChainSelector: values[0].(uint64),
			}

			result, err := mock.GetAllowedChain(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAllowedChain"].Outputs.Pack(result)
		},
		string(abi.Methods["getAllowedPeer"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAllowedPeer == nil {
				return nil, errors.New("getAllowedPeer method not mocked")
			}
			inputs := abi.Methods["getAllowedPeer"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetAllowedPeerInput{
				ChainSelector: values[0].(uint64),
			}

			result, err := mock.GetAllowedPeer(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAllowedPeer"].Outputs.Pack(result)
		},
		string(abi.Methods["getCCIPGasLimit"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCCIPGasLimit == nil {
				return nil, errors.New("getCCIPGasLimit method not mocked")
			}
			result, err := mock.GetCCIPGasLimit()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCCIPGasLimit"].Outputs.Pack(result)
		},
		string(abi.Methods["getFeeRate"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetFeeRate == nil {
				return nil, errors.New("getFeeRate method not mocked")
			}
			result, err := mock.GetFeeRate()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getFeeRate"].Outputs.Pack(result)
		},
		string(abi.Methods["getIsStrategyChain"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetIsStrategyChain == nil {
				return nil, errors.New("getIsStrategyChain method not mocked")
			}
			result, err := mock.GetIsStrategyChain()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getIsStrategyChain"].Outputs.Pack(result)
		},
		string(abi.Methods["getLink"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetLink == nil {
				return nil, errors.New("getLink method not mocked")
			}
			result, err := mock.GetLink()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getLink"].Outputs.Pack(result)
		},
		string(abi.Methods["getRebalancer"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRebalancer == nil {
				return nil, errors.New("getRebalancer method not mocked")
			}
			result, err := mock.GetRebalancer()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRebalancer"].Outputs.Pack(result)
		},
		string(abi.Methods["getRoleAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRoleAdmin == nil {
				return nil, errors.New("getRoleAdmin method not mocked")
			}
			inputs := abi.Methods["getRoleAdmin"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRoleAdminInput{
				Role: values[0].([32]byte),
			}

			result, err := mock.GetRoleAdmin(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRoleAdmin"].Outputs.Pack(result)
		},
		string(abi.Methods["getRoleMember"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRoleMember == nil {
				return nil, errors.New("getRoleMember method not mocked")
			}
			inputs := abi.Methods["getRoleMember"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := GetRoleMemberInput{
				Role:  values[0].([32]byte),
				Index: values[1].(*big.Int),
			}

			result, err := mock.GetRoleMember(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRoleMember"].Outputs.Pack(result)
		},
		string(abi.Methods["getRoleMemberCount"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRoleMemberCount == nil {
				return nil, errors.New("getRoleMemberCount method not mocked")
			}
			inputs := abi.Methods["getRoleMemberCount"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRoleMemberCountInput{
				Role: values[0].([32]byte),
			}

			result, err := mock.GetRoleMemberCount(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRoleMemberCount"].Outputs.Pack(result)
		},
		string(abi.Methods["getRoleMembers"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRoleMembers == nil {
				return nil, errors.New("getRoleMembers method not mocked")
			}
			inputs := abi.Methods["getRoleMembers"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRoleMembersInput{
				Role: values[0].([32]byte),
			}

			result, err := mock.GetRoleMembers(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRoleMembers"].Outputs.Pack(result)
		},
		string(abi.Methods["getRouter"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRouter == nil {
				return nil, errors.New("getRouter method not mocked")
			}
			result, err := mock.GetRouter()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRouter"].Outputs.Pack(result)
		},
		string(abi.Methods["getShare"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetShare == nil {
				return nil, errors.New("getShare method not mocked")
			}
			result, err := mock.GetShare()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getShare"].Outputs.Pack(result)
		},
		string(abi.Methods["getStrategy"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetStrategy == nil {
				return nil, errors.New("getStrategy method not mocked")
			}
			result, err := mock.GetStrategy()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getStrategy"].Outputs.Pack(result)
		},
		string(abi.Methods["getStrategyAdapter"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetStrategyAdapter == nil {
				return nil, errors.New("getStrategyAdapter method not mocked")
			}
			inputs := abi.Methods["getStrategyAdapter"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetStrategyAdapterInput{
				ProtocolId: values[0].([32]byte),
			}

			result, err := mock.GetStrategyAdapter(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getStrategyAdapter"].Outputs.Pack(result)
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
		string(abi.Methods["getThisChainSelector"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetThisChainSelector == nil {
				return nil, errors.New("getThisChainSelector method not mocked")
			}
			result, err := mock.GetThisChainSelector()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getThisChainSelector"].Outputs.Pack(result)
		},
		string(abi.Methods["getTotalShares"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetTotalShares == nil {
				return nil, errors.New("getTotalShares method not mocked")
			}
			result, err := mock.GetTotalShares()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getTotalShares"].Outputs.Pack(result)
		},
		string(abi.Methods["getTotalValue"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetTotalValue == nil {
				return nil, errors.New("getTotalValue method not mocked")
			}
			result, err := mock.GetTotalValue()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getTotalValue"].Outputs.Pack(result)
		},
		string(abi.Methods["getUsdc"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetUsdc == nil {
				return nil, errors.New("getUsdc method not mocked")
			}
			result, err := mock.GetUsdc()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getUsdc"].Outputs.Pack(result)
		},
		string(abi.Methods["hasRole"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.HasRole == nil {
				return nil, errors.New("hasRole method not mocked")
			}
			inputs := abi.Methods["hasRole"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := HasRoleInput{
				Role:    values[0].([32]byte),
				Account: values[1].(common.Address),
			}

			result, err := mock.HasRole(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["hasRole"].Outputs.Pack(result)
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
		string(abi.Methods["paused"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Paused == nil {
				return nil, errors.New("paused method not mocked")
			}
			result, err := mock.Paused()
			if err != nil {
				return nil, err
			}
			return abi.Methods["paused"].Outputs.Pack(result)
		},
		string(abi.Methods["pendingDefaultAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PendingDefaultAdmin == nil {
				return nil, errors.New("pendingDefaultAdmin method not mocked")
			}
			result, err := mock.PendingDefaultAdmin()
			if err != nil {
				return nil, err
			}
			return abi.Methods["pendingDefaultAdmin"].Outputs.Pack(
				result.NewAdmin,
				result.Schedule,
			)
		},
		string(abi.Methods["pendingDefaultAdminDelay"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PendingDefaultAdminDelay == nil {
				return nil, errors.New("pendingDefaultAdminDelay method not mocked")
			}
			result, err := mock.PendingDefaultAdminDelay()
			if err != nil {
				return nil, err
			}
			return abi.Methods["pendingDefaultAdminDelay"].Outputs.Pack(
				result.NewDelay,
				result.Schedule,
			)
		},
		string(abi.Methods["supportsInterface"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.SupportsInterface == nil {
				return nil, errors.New("supportsInterface method not mocked")
			}
			inputs := abi.Methods["supportsInterface"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := SupportsInterfaceInput{
				InterfaceId: values[0].([4]byte),
			}

			result, err := mock.SupportsInterface(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["supportsInterface"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
