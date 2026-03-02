// Code generated — DO NOT EDIT.

package parent_peer

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

var ParentPeerMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"ccipRouter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"usdc\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"share\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"acceptDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beginDefaultAdminTransfer\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ccipReceive\",\"inputs\":[{\"name\":\"message\",\"type\":\"tuple\",\"internalType\":\"structClient.Any2EVMMessage\",\"components\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sender\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"destTokenAmounts\",\"type\":\"tuple[]\",\"internalType\":\"structClient.EVMTokenAmount[]\",\"components\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeDefaultAdminDelay\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"defaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelayIncreaseWait\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"amountToDeposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActiveStrategyAdapter\",\"inputs\":[],\"outputs\":[{\"name\":\"activeStrategyAdapter\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllowedChain\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllowedPeer\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCCIPGasLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFeeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFeeRateDivisor\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getIsStrategyChain\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLink\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMaxFeeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getRebalancer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRouter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getShare\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structIYieldPeer.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyAdapter\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"strategyAdapter\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSupportedProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"isSupported\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getThisChainSelector\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalShares\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalValue\",\"inputs\":[],\"outputs\":[{\"name\":\"totalValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUsdc\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onTokenTransfer\",\"inputs\":[{\"name\":\"withdrawer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rebalance\",\"inputs\":[{\"name\":\"newStrategy\",\"type\":\"tuple\",\"internalType\":\"structIYieldPeer.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollbackDefaultAdminDelay\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAllowedChain\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"isAllowed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAllowedPeer\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"peer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCCIPGasLimit\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRate\",\"inputs\":[{\"name\":\"newFeeRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setInitialActiveStrategy\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRebalancer\",\"inputs\":[{\"name\":\"rebalancer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyRegistry\",\"inputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSupportedProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"isSupported\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawFees\",\"inputs\":[{\"name\":\"feeToken\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"ActiveStrategyAdapterUpdated\",\"inputs\":[{\"name\":\"activeStrategyAdapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AllowedChainSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"isAllowed\",\"type\":\"bool\",\"indexed\":true,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AllowedPeerSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"peer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPGasLimitSet\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPMessageReceived\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"txType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumIYieldPeer.CcipTxType\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPMessageSent\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"txType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumIYieldPeer.CcipTxType\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeScheduled\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"},{\"name\":\"effectSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferScheduled\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"acceptSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositForwardedToStrategy\",\"inputs\":[{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"strategyChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositInitiated\",\"inputs\":[{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositPingPongToChild\",\"inputs\":[{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"destChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositToStrategy\",\"inputs\":[{\"name\":\"strategyAdapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeRateSet\",\"inputs\":[{\"name\":\"feeRate\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeTaken\",\"inputs\":[{\"name\":\"feeAmountInStablecoin\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeesWithdrawn\",\"inputs\":[{\"name\":\"feesWithdrawn\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalancerSet\",\"inputs\":[{\"name\":\"rebalancer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ShareBurnUpdate\",\"inputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"totalShares\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ShareMintUpdate\",\"inputs\":[{\"name\":\"shareMintAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"totalShares\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SharesBurned\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SharesMinted\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyRegistrySet\",\"inputs\":[{\"name\":\"strategyRegistry\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUpdated\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"oldChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SupportedProtocolSet\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"isSupported\",\"type\":\"bool\",\"indexed\":true,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawCompleted\",\"inputs\":[{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawForwardedToStrategy\",\"inputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"strategyChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFromStrategy\",\"inputs\":[{\"name\":\"strategyAdapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawInitiated\",\"inputs\":[{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawPingPongToChild\",\"inputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"destChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminDelay\",\"inputs\":[{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminRules\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlInvalidDefaultAdmin\",\"inputs\":[{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"CCIPOperations__InvalidToken\",\"inputs\":[{\"name\":\"invalidToken\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"CCIPOperations__InvalidTokenAmount\",\"inputs\":[{\"name\":\"invalidAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"CCIPOperations__NotEnoughLink\",\"inputs\":[{\"name\":\"linkBalance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"fees\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidRouter\",\"inputs\":[{\"name\":\"router\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ParentPeer__CurrentStrategyOptimal\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentPeer__InactiveStrategyAdapter\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentPeer__InitialActiveStrategyAlreadySet\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentPeer__OnlyRebalancer\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentPeer__StrategyNotSupported\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"SafeCastOverflowedUintDowncast\",\"inputs\":[{\"name\":\"bits\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"YieldFees__FeeRateTooHigh\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldFees__NoFeesToWithdraw\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldPeer__ChainNotAllowed\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"YieldPeer__InsufficientAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldPeer__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldPeer__NotStrategyChain\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldPeer__OnlyShare\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YieldPeer__PeerNotAllowed\",\"inputs\":[{\"name\":\"peer\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// Structs
type ClientAny2EVMMessage struct {
	MessageId           [32]byte
	SourceChainSelector uint64
	Sender              []byte
	Data                []byte
	DestTokenAmounts    []ClientEVMTokenAmount
}

type ClientEVMTokenAmount struct {
	Token  common.Address
	Amount *big.Int
}

type IYieldPeerStrategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

// Contract Method Inputs
type BeginDefaultAdminTransferInput struct {
	NewAdmin common.Address
}

type CcipReceiveInput struct {
	Message ClientAny2EVMMessage
}

type ChangeDefaultAdminDelayInput struct {
	NewDelay *big.Int
}

type DepositInput struct {
	AmountToDeposit *big.Int
}

type GetAllowedChainInput struct {
	ChainSelector uint64
}

type GetAllowedPeerInput struct {
	ChainSelector uint64
}

type GetRoleAdminInput struct {
	Role [32]byte
}

type GetStrategyAdapterInput struct {
	ProtocolId [32]byte
}

type GetSupportedProtocolInput struct {
	ProtocolId [32]byte
}

type GrantRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type HasRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type OnTokenTransferInput struct {
	Withdrawer      common.Address
	ShareBurnAmount *big.Int
	Arg2            []byte
}

type RebalanceInput struct {
	NewStrategy IYieldPeerStrategy
}

type RenounceRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type RevokeRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type SetAllowedChainInput struct {
	ChainSelector uint64
	IsAllowed     bool
}

type SetAllowedPeerInput struct {
	ChainSelector uint64
	Peer          common.Address
}

type SetCCIPGasLimitInput struct {
	GasLimit *big.Int
}

type SetFeeRateInput struct {
	NewFeeRate *big.Int
}

type SetInitialActiveStrategyInput struct {
	ProtocolId [32]byte
}

type SetRebalancerInput struct {
	Rebalancer common.Address
}

type SetStrategyRegistryInput struct {
	StrategyRegistry common.Address
}

type SetSupportedProtocolInput struct {
	ProtocolId  [32]byte
	IsSupported bool
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type WithdrawFeesInput struct {
	FeeToken common.Address
}

// Contract Method Outputs
type PendingDefaultAdminOutput struct {
	NewAdmin common.Address
	Schedule *big.Int
}

type PendingDefaultAdminDelayOutput struct {
	NewDelay *big.Int
	Schedule *big.Int
}

// Errors
type AccessControlBadConfirmation struct {
}

type AccessControlEnforcedDefaultAdminDelay struct {
	Schedule *big.Int
}

type AccessControlEnforcedDefaultAdminRules struct {
}

type AccessControlInvalidDefaultAdmin struct {
	DefaultAdmin common.Address
}

type AccessControlUnauthorizedAccount struct {
	Account    common.Address
	NeededRole [32]byte
}

type CCIPOperationsInvalidToken struct {
	InvalidToken common.Address
}

type CCIPOperationsInvalidTokenAmount struct {
	InvalidAmount *big.Int
}

type CCIPOperationsNotEnoughLink struct {
	LinkBalance *big.Int
	Fees        *big.Int
}

type EnforcedPause struct {
}

type ExpectedPause struct {
}

type InvalidRouter struct {
	Router common.Address
}

type ParentPeerCurrentStrategyOptimal struct {
}

type ParentPeerInactiveStrategyAdapter struct {
}

type ParentPeerInitialActiveStrategyAlreadySet struct {
}

type ParentPeerOnlyRebalancer struct {
}

type ParentPeerStrategyNotSupported struct {
	ProtocolId [32]byte
}

type SafeCastOverflowedUintDowncast struct {
	Bits  uint8
	Value *big.Int
}

type SafeERC20FailedOperation struct {
	Token common.Address
}

type YieldFeesFeeRateTooHigh struct {
}

type YieldFeesNoFeesToWithdraw struct {
}

type YieldPeerChainNotAllowed struct {
	ChainSelector uint64
}

type YieldPeerInsufficientAmount struct {
}

type YieldPeerNoZeroAmount struct {
}

type YieldPeerNotStrategyChain struct {
}

type YieldPeerOnlyShare struct {
}

type YieldPeerPeerNotAllowed struct {
	Peer common.Address
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

type ActiveStrategyAdapterUpdatedTopics struct {
	ActiveStrategyAdapter common.Address
}

type ActiveStrategyAdapterUpdatedDecoded struct {
	ActiveStrategyAdapter common.Address
}

type AllowedChainSetTopics struct {
	ChainSelector uint64
	IsAllowed     bool
}

type AllowedChainSetDecoded struct {
	ChainSelector uint64
	IsAllowed     bool
}

type AllowedPeerSetTopics struct {
	ChainSelector uint64
	Peer          common.Address
}

type AllowedPeerSetDecoded struct {
	ChainSelector uint64
	Peer          common.Address
}

type CCIPGasLimitSetTopics struct {
	GasLimit *big.Int
}

type CCIPGasLimitSetDecoded struct {
	GasLimit *big.Int
}

type CCIPMessageReceivedTopics struct {
	MessageId           [32]byte
	TxType              uint8
	SourceChainSelector uint64
}

type CCIPMessageReceivedDecoded struct {
	MessageId           [32]byte
	TxType              uint8
	SourceChainSelector uint64
}

type CCIPMessageSentTopics struct {
	MessageId [32]byte
	TxType    uint8
	Amount    *big.Int
}

type CCIPMessageSentDecoded struct {
	MessageId [32]byte
	TxType    uint8
	Amount    *big.Int
}

type DefaultAdminDelayChangeCanceledTopics struct {
}

type DefaultAdminDelayChangeCanceledDecoded struct {
}

type DefaultAdminDelayChangeScheduledTopics struct {
}

type DefaultAdminDelayChangeScheduledDecoded struct {
	NewDelay       *big.Int
	EffectSchedule *big.Int
}

type DefaultAdminTransferCanceledTopics struct {
}

type DefaultAdminTransferCanceledDecoded struct {
}

type DefaultAdminTransferScheduledTopics struct {
	NewAdmin common.Address
}

type DefaultAdminTransferScheduledDecoded struct {
	NewAdmin       common.Address
	AcceptSchedule *big.Int
}

type DepositForwardedToStrategyTopics struct {
	DepositAmount         *big.Int
	StrategyChainSelector uint64
}

type DepositForwardedToStrategyDecoded struct {
	DepositAmount         *big.Int
	StrategyChainSelector uint64
}

type DepositInitiatedTopics struct {
	Depositor         common.Address
	Amount            *big.Int
	ThisChainSelector uint64
}

type DepositInitiatedDecoded struct {
	Depositor         common.Address
	Amount            *big.Int
	ThisChainSelector uint64
}

type DepositPingPongToChildTopics struct {
	DepositAmount     *big.Int
	DestChainSelector uint64
}

type DepositPingPongToChildDecoded struct {
	DepositAmount     *big.Int
	DestChainSelector uint64
}

type DepositToStrategyTopics struct {
	StrategyAdapter common.Address
	Amount          *big.Int
}

type DepositToStrategyDecoded struct {
	StrategyAdapter common.Address
	Amount          *big.Int
}

type FeeRateSetTopics struct {
	FeeRate *big.Int
}

type FeeRateSetDecoded struct {
	FeeRate *big.Int
}

type FeeTakenTopics struct {
	FeeAmountInStablecoin *big.Int
}

type FeeTakenDecoded struct {
	FeeAmountInStablecoin *big.Int
}

type FeesWithdrawnTopics struct {
	FeesWithdrawn *big.Int
}

type FeesWithdrawnDecoded struct {
	FeesWithdrawn *big.Int
}

type PausedTopics struct {
}

type PausedDecoded struct {
	Account common.Address
}

type RebalancerSetTopics struct {
	Rebalancer common.Address
}

type RebalancerSetDecoded struct {
	Rebalancer common.Address
}

type RoleAdminChangedTopics struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
}

type RoleAdminChangedDecoded struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
}

type RoleGrantedTopics struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleGrantedDecoded struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleRevokedTopics struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleRevokedDecoded struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type ShareBurnUpdateTopics struct {
	ShareBurnAmount *big.Int
	ChainSelector   uint64
	TotalShares     *big.Int
}

type ShareBurnUpdateDecoded struct {
	ShareBurnAmount *big.Int
	ChainSelector   uint64
	TotalShares     *big.Int
}

type ShareMintUpdateTopics struct {
	ShareMintAmount *big.Int
	ChainSelector   uint64
	TotalShares     *big.Int
}

type ShareMintUpdateDecoded struct {
	ShareMintAmount *big.Int
	ChainSelector   uint64
	TotalShares     *big.Int
}

type SharesBurnedTopics struct {
	From   common.Address
	Amount *big.Int
}

type SharesBurnedDecoded struct {
	From   common.Address
	Amount *big.Int
}

type SharesMintedTopics struct {
	To     common.Address
	Amount *big.Int
}

type SharesMintedDecoded struct {
	To     common.Address
	Amount *big.Int
}

type StrategyRegistrySetTopics struct {
	StrategyRegistry common.Address
}

type StrategyRegistrySetDecoded struct {
	StrategyRegistry common.Address
}

type StrategyUpdatedTopics struct {
	ChainSelector    uint64
	ProtocolId       [32]byte
	OldChainSelector uint64
}

type StrategyUpdatedDecoded struct {
	ChainSelector    uint64
	ProtocolId       [32]byte
	OldChainSelector uint64
}

type SupportedProtocolSetTopics struct {
	ProtocolId  [32]byte
	IsSupported bool
}

type SupportedProtocolSetDecoded struct {
	ProtocolId  [32]byte
	IsSupported bool
}

type UnpausedTopics struct {
}

type UnpausedDecoded struct {
	Account common.Address
}

type WithdrawCompletedTopics struct {
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawCompletedDecoded struct {
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawForwardedToStrategyTopics struct {
	ShareBurnAmount       *big.Int
	StrategyChainSelector uint64
}

type WithdrawForwardedToStrategyDecoded struct {
	ShareBurnAmount       *big.Int
	StrategyChainSelector uint64
}

type WithdrawFromStrategyTopics struct {
	StrategyAdapter common.Address
	Amount          *big.Int
}

type WithdrawFromStrategyDecoded struct {
	StrategyAdapter common.Address
	Amount          *big.Int
}

type WithdrawInitiatedTopics struct {
	Withdrawer        common.Address
	Amount            *big.Int
	ThisChainSelector uint64
}

type WithdrawInitiatedDecoded struct {
	Withdrawer        common.Address
	Amount            *big.Int
	ThisChainSelector uint64
}

type WithdrawPingPongToChildTopics struct {
	ShareBurnAmount   *big.Int
	DestChainSelector uint64
}

type WithdrawPingPongToChildDecoded struct {
	ShareBurnAmount   *big.Int
	DestChainSelector uint64
}

// Main Binding Type for ParentPeer
type ParentPeer struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   ParentPeerCodec
}

type ParentPeerCodec interface {
	EncodeDEFAULTADMINROLEMethodCall() ([]byte, error)
	DecodeDEFAULTADMINROLEMethodOutput(data []byte) ([32]byte, error)
	EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error)
	EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error)
	EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error)
	EncodeDefaultAdminMethodCall() ([]byte, error)
	DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error)
	EncodeDefaultAdminDelayMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error)
	EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error)
	EncodeDepositMethodCall(in DepositInput) ([]byte, error)
	EncodeGetActiveStrategyAdapterMethodCall() ([]byte, error)
	DecodeGetActiveStrategyAdapterMethodOutput(data []byte) (common.Address, error)
	EncodeGetAllowedChainMethodCall(in GetAllowedChainInput) ([]byte, error)
	DecodeGetAllowedChainMethodOutput(data []byte) (bool, error)
	EncodeGetAllowedPeerMethodCall(in GetAllowedPeerInput) ([]byte, error)
	DecodeGetAllowedPeerMethodOutput(data []byte) (common.Address, error)
	EncodeGetCCIPGasLimitMethodCall() ([]byte, error)
	DecodeGetCCIPGasLimitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetFeeRateMethodCall() ([]byte, error)
	DecodeGetFeeRateMethodOutput(data []byte) (*big.Int, error)
	EncodeGetFeeRateDivisorMethodCall() ([]byte, error)
	DecodeGetFeeRateDivisorMethodOutput(data []byte) (*big.Int, error)
	EncodeGetIsStrategyChainMethodCall() ([]byte, error)
	DecodeGetIsStrategyChainMethodOutput(data []byte) (bool, error)
	EncodeGetLinkMethodCall() ([]byte, error)
	DecodeGetLinkMethodOutput(data []byte) (common.Address, error)
	EncodeGetMaxFeeRateMethodCall() ([]byte, error)
	DecodeGetMaxFeeRateMethodOutput(data []byte) (*big.Int, error)
	EncodeGetRebalancerMethodCall() ([]byte, error)
	DecodeGetRebalancerMethodOutput(data []byte) (common.Address, error)
	EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error)
	DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error)
	EncodeGetRouterMethodCall() ([]byte, error)
	DecodeGetRouterMethodOutput(data []byte) (common.Address, error)
	EncodeGetShareMethodCall() ([]byte, error)
	DecodeGetShareMethodOutput(data []byte) (common.Address, error)
	EncodeGetStrategyMethodCall() ([]byte, error)
	DecodeGetStrategyMethodOutput(data []byte) (IYieldPeerStrategy, error)
	EncodeGetStrategyAdapterMethodCall(in GetStrategyAdapterInput) ([]byte, error)
	DecodeGetStrategyAdapterMethodOutput(data []byte) (common.Address, error)
	EncodeGetStrategyRegistryMethodCall() ([]byte, error)
	DecodeGetStrategyRegistryMethodOutput(data []byte) (common.Address, error)
	EncodeGetSupportedProtocolMethodCall(in GetSupportedProtocolInput) ([]byte, error)
	DecodeGetSupportedProtocolMethodOutput(data []byte) (bool, error)
	EncodeGetThisChainSelectorMethodCall() ([]byte, error)
	DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error)
	EncodeGetTotalSharesMethodCall() ([]byte, error)
	DecodeGetTotalSharesMethodOutput(data []byte) (*big.Int, error)
	EncodeGetTotalValueMethodCall() ([]byte, error)
	DecodeGetTotalValueMethodOutput(data []byte) (*big.Int, error)
	EncodeGetUsdcMethodCall() ([]byte, error)
	DecodeGetUsdcMethodOutput(data []byte) (common.Address, error)
	EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error)
	EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error)
	DecodeHasRoleMethodOutput(data []byte) (bool, error)
	EncodeOnTokenTransferMethodCall(in OnTokenTransferInput) ([]byte, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodePauseMethodCall() ([]byte, error)
	EncodePausedMethodCall() ([]byte, error)
	DecodePausedMethodOutput(data []byte) (bool, error)
	EncodePendingDefaultAdminMethodCall() ([]byte, error)
	DecodePendingDefaultAdminMethodOutput(data []byte) (PendingDefaultAdminOutput, error)
	EncodePendingDefaultAdminDelayMethodCall() ([]byte, error)
	DecodePendingDefaultAdminDelayMethodOutput(data []byte) (PendingDefaultAdminDelayOutput, error)
	EncodeRebalanceMethodCall(in RebalanceInput) ([]byte, error)
	EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error)
	EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error)
	EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error)
	EncodeSetAllowedChainMethodCall(in SetAllowedChainInput) ([]byte, error)
	EncodeSetAllowedPeerMethodCall(in SetAllowedPeerInput) ([]byte, error)
	EncodeSetCCIPGasLimitMethodCall(in SetCCIPGasLimitInput) ([]byte, error)
	EncodeSetFeeRateMethodCall(in SetFeeRateInput) ([]byte, error)
	EncodeSetInitialActiveStrategyMethodCall(in SetInitialActiveStrategyInput) ([]byte, error)
	EncodeSetRebalancerMethodCall(in SetRebalancerInput) ([]byte, error)
	EncodeSetStrategyRegistryMethodCall(in SetStrategyRegistryInput) ([]byte, error)
	EncodeSetSupportedProtocolMethodCall(in SetSupportedProtocolInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeUnpauseMethodCall() ([]byte, error)
	EncodeWithdrawFeesMethodCall(in WithdrawFeesInput) ([]byte, error)
	EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error)
	EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error)
	EncodeIYieldPeerStrategyStruct(in IYieldPeerStrategy) ([]byte, error)
	ActiveStrategyAdapterUpdatedLogHash() []byte
	EncodeActiveStrategyAdapterUpdatedTopics(evt abi.Event, values []ActiveStrategyAdapterUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeActiveStrategyAdapterUpdated(log *evm.Log) (*ActiveStrategyAdapterUpdatedDecoded, error)
	AllowedChainSetLogHash() []byte
	EncodeAllowedChainSetTopics(evt abi.Event, values []AllowedChainSetTopics) ([]*evm.TopicValues, error)
	DecodeAllowedChainSet(log *evm.Log) (*AllowedChainSetDecoded, error)
	AllowedPeerSetLogHash() []byte
	EncodeAllowedPeerSetTopics(evt abi.Event, values []AllowedPeerSetTopics) ([]*evm.TopicValues, error)
	DecodeAllowedPeerSet(log *evm.Log) (*AllowedPeerSetDecoded, error)
	CCIPGasLimitSetLogHash() []byte
	EncodeCCIPGasLimitSetTopics(evt abi.Event, values []CCIPGasLimitSetTopics) ([]*evm.TopicValues, error)
	DecodeCCIPGasLimitSet(log *evm.Log) (*CCIPGasLimitSetDecoded, error)
	CCIPMessageReceivedLogHash() []byte
	EncodeCCIPMessageReceivedTopics(evt abi.Event, values []CCIPMessageReceivedTopics) ([]*evm.TopicValues, error)
	DecodeCCIPMessageReceived(log *evm.Log) (*CCIPMessageReceivedDecoded, error)
	CCIPMessageSentLogHash() []byte
	EncodeCCIPMessageSentTopics(evt abi.Event, values []CCIPMessageSentTopics) ([]*evm.TopicValues, error)
	DecodeCCIPMessageSent(log *evm.Log) (*CCIPMessageSentDecoded, error)
	DefaultAdminDelayChangeCanceledLogHash() []byte
	EncodeDefaultAdminDelayChangeCanceledTopics(evt abi.Event, values []DefaultAdminDelayChangeCanceledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminDelayChangeCanceled(log *evm.Log) (*DefaultAdminDelayChangeCanceledDecoded, error)
	DefaultAdminDelayChangeScheduledLogHash() []byte
	EncodeDefaultAdminDelayChangeScheduledTopics(evt abi.Event, values []DefaultAdminDelayChangeScheduledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminDelayChangeScheduled(log *evm.Log) (*DefaultAdminDelayChangeScheduledDecoded, error)
	DefaultAdminTransferCanceledLogHash() []byte
	EncodeDefaultAdminTransferCanceledTopics(evt abi.Event, values []DefaultAdminTransferCanceledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminTransferCanceled(log *evm.Log) (*DefaultAdminTransferCanceledDecoded, error)
	DefaultAdminTransferScheduledLogHash() []byte
	EncodeDefaultAdminTransferScheduledTopics(evt abi.Event, values []DefaultAdminTransferScheduledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminTransferScheduled(log *evm.Log) (*DefaultAdminTransferScheduledDecoded, error)
	DepositForwardedToStrategyLogHash() []byte
	EncodeDepositForwardedToStrategyTopics(evt abi.Event, values []DepositForwardedToStrategyTopics) ([]*evm.TopicValues, error)
	DecodeDepositForwardedToStrategy(log *evm.Log) (*DepositForwardedToStrategyDecoded, error)
	DepositInitiatedLogHash() []byte
	EncodeDepositInitiatedTopics(evt abi.Event, values []DepositInitiatedTopics) ([]*evm.TopicValues, error)
	DecodeDepositInitiated(log *evm.Log) (*DepositInitiatedDecoded, error)
	DepositPingPongToChildLogHash() []byte
	EncodeDepositPingPongToChildTopics(evt abi.Event, values []DepositPingPongToChildTopics) ([]*evm.TopicValues, error)
	DecodeDepositPingPongToChild(log *evm.Log) (*DepositPingPongToChildDecoded, error)
	DepositToStrategyLogHash() []byte
	EncodeDepositToStrategyTopics(evt abi.Event, values []DepositToStrategyTopics) ([]*evm.TopicValues, error)
	DecodeDepositToStrategy(log *evm.Log) (*DepositToStrategyDecoded, error)
	FeeRateSetLogHash() []byte
	EncodeFeeRateSetTopics(evt abi.Event, values []FeeRateSetTopics) ([]*evm.TopicValues, error)
	DecodeFeeRateSet(log *evm.Log) (*FeeRateSetDecoded, error)
	FeeTakenLogHash() []byte
	EncodeFeeTakenTopics(evt abi.Event, values []FeeTakenTopics) ([]*evm.TopicValues, error)
	DecodeFeeTaken(log *evm.Log) (*FeeTakenDecoded, error)
	FeesWithdrawnLogHash() []byte
	EncodeFeesWithdrawnTopics(evt abi.Event, values []FeesWithdrawnTopics) ([]*evm.TopicValues, error)
	DecodeFeesWithdrawn(log *evm.Log) (*FeesWithdrawnDecoded, error)
	PausedLogHash() []byte
	EncodePausedTopics(evt abi.Event, values []PausedTopics) ([]*evm.TopicValues, error)
	DecodePaused(log *evm.Log) (*PausedDecoded, error)
	RebalancerSetLogHash() []byte
	EncodeRebalancerSetTopics(evt abi.Event, values []RebalancerSetTopics) ([]*evm.TopicValues, error)
	DecodeRebalancerSet(log *evm.Log) (*RebalancerSetDecoded, error)
	RoleAdminChangedLogHash() []byte
	EncodeRoleAdminChangedTopics(evt abi.Event, values []RoleAdminChangedTopics) ([]*evm.TopicValues, error)
	DecodeRoleAdminChanged(log *evm.Log) (*RoleAdminChangedDecoded, error)
	RoleGrantedLogHash() []byte
	EncodeRoleGrantedTopics(evt abi.Event, values []RoleGrantedTopics) ([]*evm.TopicValues, error)
	DecodeRoleGranted(log *evm.Log) (*RoleGrantedDecoded, error)
	RoleRevokedLogHash() []byte
	EncodeRoleRevokedTopics(evt abi.Event, values []RoleRevokedTopics) ([]*evm.TopicValues, error)
	DecodeRoleRevoked(log *evm.Log) (*RoleRevokedDecoded, error)
	ShareBurnUpdateLogHash() []byte
	EncodeShareBurnUpdateTopics(evt abi.Event, values []ShareBurnUpdateTopics) ([]*evm.TopicValues, error)
	DecodeShareBurnUpdate(log *evm.Log) (*ShareBurnUpdateDecoded, error)
	ShareMintUpdateLogHash() []byte
	EncodeShareMintUpdateTopics(evt abi.Event, values []ShareMintUpdateTopics) ([]*evm.TopicValues, error)
	DecodeShareMintUpdate(log *evm.Log) (*ShareMintUpdateDecoded, error)
	SharesBurnedLogHash() []byte
	EncodeSharesBurnedTopics(evt abi.Event, values []SharesBurnedTopics) ([]*evm.TopicValues, error)
	DecodeSharesBurned(log *evm.Log) (*SharesBurnedDecoded, error)
	SharesMintedLogHash() []byte
	EncodeSharesMintedTopics(evt abi.Event, values []SharesMintedTopics) ([]*evm.TopicValues, error)
	DecodeSharesMinted(log *evm.Log) (*SharesMintedDecoded, error)
	StrategyRegistrySetLogHash() []byte
	EncodeStrategyRegistrySetTopics(evt abi.Event, values []StrategyRegistrySetTopics) ([]*evm.TopicValues, error)
	DecodeStrategyRegistrySet(log *evm.Log) (*StrategyRegistrySetDecoded, error)
	StrategyUpdatedLogHash() []byte
	EncodeStrategyUpdatedTopics(evt abi.Event, values []StrategyUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeStrategyUpdated(log *evm.Log) (*StrategyUpdatedDecoded, error)
	SupportedProtocolSetLogHash() []byte
	EncodeSupportedProtocolSetTopics(evt abi.Event, values []SupportedProtocolSetTopics) ([]*evm.TopicValues, error)
	DecodeSupportedProtocolSet(log *evm.Log) (*SupportedProtocolSetDecoded, error)
	UnpausedLogHash() []byte
	EncodeUnpausedTopics(evt abi.Event, values []UnpausedTopics) ([]*evm.TopicValues, error)
	DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error)
	WithdrawCompletedLogHash() []byte
	EncodeWithdrawCompletedTopics(evt abi.Event, values []WithdrawCompletedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawCompleted(log *evm.Log) (*WithdrawCompletedDecoded, error)
	WithdrawForwardedToStrategyLogHash() []byte
	EncodeWithdrawForwardedToStrategyTopics(evt abi.Event, values []WithdrawForwardedToStrategyTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawForwardedToStrategy(log *evm.Log) (*WithdrawForwardedToStrategyDecoded, error)
	WithdrawFromStrategyLogHash() []byte
	EncodeWithdrawFromStrategyTopics(evt abi.Event, values []WithdrawFromStrategyTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFromStrategy(log *evm.Log) (*WithdrawFromStrategyDecoded, error)
	WithdrawInitiatedLogHash() []byte
	EncodeWithdrawInitiatedTopics(evt abi.Event, values []WithdrawInitiatedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawInitiated(log *evm.Log) (*WithdrawInitiatedDecoded, error)
	WithdrawPingPongToChildLogHash() []byte
	EncodeWithdrawPingPongToChildTopics(evt abi.Event, values []WithdrawPingPongToChildTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawPingPongToChild(log *evm.Log) (*WithdrawPingPongToChildDecoded, error)
}

func NewParentPeer(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*ParentPeer, error) {
	parsed, err := abi.JSON(strings.NewReader(ParentPeerMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &ParentPeer{
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

func NewCodec() (ParentPeerCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(ParentPeerMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeDEFAULTADMINROLEMethodCall() ([]byte, error) {
	return c.abi.Pack("DEFAULT_ADMIN_ROLE")
}

func (c *Codec) DecodeDEFAULTADMINROLEMethodOutput(data []byte) ([32]byte, error) {
	vals, err := c.abi.Methods["DEFAULT_ADMIN_ROLE"].Outputs.Unpack(data)
	if err != nil {
		return *new([32]byte), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([32]byte), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result [32]byte
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([32]byte), fmt.Errorf("failed to unmarshal to [32]byte: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error) {
	return c.abi.Pack("acceptDefaultAdminTransfer")
}

func (c *Codec) EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error) {
	return c.abi.Pack("beginDefaultAdminTransfer", in.NewAdmin)
}

func (c *Codec) EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error) {
	return c.abi.Pack("cancelDefaultAdminTransfer")
}

func (c *Codec) EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error) {
	return c.abi.Pack("ccipReceive", in.Message)
}

func (c *Codec) EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error) {
	return c.abi.Pack("changeDefaultAdminDelay", in.NewDelay)
}

func (c *Codec) EncodeDefaultAdminMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdmin")
}

func (c *Codec) DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["defaultAdmin"].Outputs.Unpack(data)
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

func (c *Codec) EncodeDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdminDelay")
}

func (c *Codec) DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["defaultAdminDelay"].Outputs.Unpack(data)
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

func (c *Codec) EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdminDelayIncreaseWait")
}

func (c *Codec) DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["defaultAdminDelayIncreaseWait"].Outputs.Unpack(data)
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

func (c *Codec) EncodeDepositMethodCall(in DepositInput) ([]byte, error) {
	return c.abi.Pack("deposit", in.AmountToDeposit)
}

func (c *Codec) EncodeGetActiveStrategyAdapterMethodCall() ([]byte, error) {
	return c.abi.Pack("getActiveStrategyAdapter")
}

func (c *Codec) DecodeGetActiveStrategyAdapterMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getActiveStrategyAdapter"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetAllowedChainMethodCall(in GetAllowedChainInput) ([]byte, error) {
	return c.abi.Pack("getAllowedChain", in.ChainSelector)
}

func (c *Codec) DecodeGetAllowedChainMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getAllowedChain"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetAllowedPeerMethodCall(in GetAllowedPeerInput) ([]byte, error) {
	return c.abi.Pack("getAllowedPeer", in.ChainSelector)
}

func (c *Codec) DecodeGetAllowedPeerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getAllowedPeer"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetCCIPGasLimitMethodCall() ([]byte, error) {
	return c.abi.Pack("getCCIPGasLimit")
}

func (c *Codec) DecodeGetCCIPGasLimitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getCCIPGasLimit"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetFeeRateMethodCall() ([]byte, error) {
	return c.abi.Pack("getFeeRate")
}

func (c *Codec) DecodeGetFeeRateMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getFeeRate"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetFeeRateDivisorMethodCall() ([]byte, error) {
	return c.abi.Pack("getFeeRateDivisor")
}

func (c *Codec) DecodeGetFeeRateDivisorMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getFeeRateDivisor"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetIsStrategyChainMethodCall() ([]byte, error) {
	return c.abi.Pack("getIsStrategyChain")
}

func (c *Codec) DecodeGetIsStrategyChainMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getIsStrategyChain"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetLinkMethodCall() ([]byte, error) {
	return c.abi.Pack("getLink")
}

func (c *Codec) DecodeGetLinkMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getLink"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetMaxFeeRateMethodCall() ([]byte, error) {
	return c.abi.Pack("getMaxFeeRate")
}

func (c *Codec) DecodeGetMaxFeeRateMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getMaxFeeRate"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetRebalancerMethodCall() ([]byte, error) {
	return c.abi.Pack("getRebalancer")
}

func (c *Codec) DecodeGetRebalancerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getRebalancer"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error) {
	return c.abi.Pack("getRoleAdmin", in.Role)
}

func (c *Codec) DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error) {
	vals, err := c.abi.Methods["getRoleAdmin"].Outputs.Unpack(data)
	if err != nil {
		return *new([32]byte), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([32]byte), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result [32]byte
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([32]byte), fmt.Errorf("failed to unmarshal to [32]byte: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRouterMethodCall() ([]byte, error) {
	return c.abi.Pack("getRouter")
}

func (c *Codec) DecodeGetRouterMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getRouter"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetShareMethodCall() ([]byte, error) {
	return c.abi.Pack("getShare")
}

func (c *Codec) DecodeGetShareMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getShare"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetStrategyMethodCall() ([]byte, error) {
	return c.abi.Pack("getStrategy")
}

func (c *Codec) DecodeGetStrategyMethodOutput(data []byte) (IYieldPeerStrategy, error) {
	vals, err := c.abi.Methods["getStrategy"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetStrategyAdapterMethodCall(in GetStrategyAdapterInput) ([]byte, error) {
	return c.abi.Pack("getStrategyAdapter", in.ProtocolId)
}

func (c *Codec) DecodeGetStrategyAdapterMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getStrategyAdapter"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetSupportedProtocolMethodCall(in GetSupportedProtocolInput) ([]byte, error) {
	return c.abi.Pack("getSupportedProtocol", in.ProtocolId)
}

func (c *Codec) DecodeGetSupportedProtocolMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getSupportedProtocol"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetThisChainSelectorMethodCall() ([]byte, error) {
	return c.abi.Pack("getThisChainSelector")
}

func (c *Codec) DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error) {
	vals, err := c.abi.Methods["getThisChainSelector"].Outputs.Unpack(data)
	if err != nil {
		return *new(uint64), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(uint64), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result uint64
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(uint64), fmt.Errorf("failed to unmarshal to uint64: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetTotalSharesMethodCall() ([]byte, error) {
	return c.abi.Pack("getTotalShares")
}

func (c *Codec) DecodeGetTotalSharesMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getTotalShares"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetTotalValueMethodCall() ([]byte, error) {
	return c.abi.Pack("getTotalValue")
}

func (c *Codec) DecodeGetTotalValueMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getTotalValue"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetUsdcMethodCall() ([]byte, error) {
	return c.abi.Pack("getUsdc")
}

func (c *Codec) DecodeGetUsdcMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getUsdc"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error) {
	return c.abi.Pack("grantRole", in.Role, in.Account)
}

func (c *Codec) EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error) {
	return c.abi.Pack("hasRole", in.Role, in.Account)
}

func (c *Codec) DecodeHasRoleMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["hasRole"].Outputs.Unpack(data)
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

func (c *Codec) EncodeOnTokenTransferMethodCall(in OnTokenTransferInput) ([]byte, error) {
	return c.abi.Pack("onTokenTransfer", in.Withdrawer, in.ShareBurnAmount, in.Arg2)
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

func (c *Codec) EncodePauseMethodCall() ([]byte, error) {
	return c.abi.Pack("pause")
}

func (c *Codec) EncodePausedMethodCall() ([]byte, error) {
	return c.abi.Pack("paused")
}

func (c *Codec) DecodePausedMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["paused"].Outputs.Unpack(data)
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

func (c *Codec) EncodePendingDefaultAdminMethodCall() ([]byte, error) {
	return c.abi.Pack("pendingDefaultAdmin")
}

func (c *Codec) DecodePendingDefaultAdminMethodOutput(data []byte) (PendingDefaultAdminOutput, error) {
	vals, err := c.abi.Methods["pendingDefaultAdmin"].Outputs.Unpack(data)
	if err != nil {
		return PendingDefaultAdminOutput{}, err
	}
	if len(vals) != 2 {
		return PendingDefaultAdminOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 common.Address
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return PendingDefaultAdminOutput{
		NewAdmin: result0,
		Schedule: result1,
	}, nil
}

func (c *Codec) EncodePendingDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("pendingDefaultAdminDelay")
}

func (c *Codec) DecodePendingDefaultAdminDelayMethodOutput(data []byte) (PendingDefaultAdminDelayOutput, error) {
	vals, err := c.abi.Methods["pendingDefaultAdminDelay"].Outputs.Unpack(data)
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, err
	}
	if len(vals) != 2 {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return PendingDefaultAdminDelayOutput{
		NewDelay: result0,
		Schedule: result1,
	}, nil
}

func (c *Codec) EncodeRebalanceMethodCall(in RebalanceInput) ([]byte, error) {
	return c.abi.Pack("rebalance", in.NewStrategy)
}

func (c *Codec) EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error) {
	return c.abi.Pack("renounceRole", in.Role, in.Account)
}

func (c *Codec) EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error) {
	return c.abi.Pack("revokeRole", in.Role, in.Account)
}

func (c *Codec) EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("rollbackDefaultAdminDelay")
}

func (c *Codec) EncodeSetAllowedChainMethodCall(in SetAllowedChainInput) ([]byte, error) {
	return c.abi.Pack("setAllowedChain", in.ChainSelector, in.IsAllowed)
}

func (c *Codec) EncodeSetAllowedPeerMethodCall(in SetAllowedPeerInput) ([]byte, error) {
	return c.abi.Pack("setAllowedPeer", in.ChainSelector, in.Peer)
}

func (c *Codec) EncodeSetCCIPGasLimitMethodCall(in SetCCIPGasLimitInput) ([]byte, error) {
	return c.abi.Pack("setCCIPGasLimit", in.GasLimit)
}

func (c *Codec) EncodeSetFeeRateMethodCall(in SetFeeRateInput) ([]byte, error) {
	return c.abi.Pack("setFeeRate", in.NewFeeRate)
}

func (c *Codec) EncodeSetInitialActiveStrategyMethodCall(in SetInitialActiveStrategyInput) ([]byte, error) {
	return c.abi.Pack("setInitialActiveStrategy", in.ProtocolId)
}

func (c *Codec) EncodeSetRebalancerMethodCall(in SetRebalancerInput) ([]byte, error) {
	return c.abi.Pack("setRebalancer", in.Rebalancer)
}

func (c *Codec) EncodeSetStrategyRegistryMethodCall(in SetStrategyRegistryInput) ([]byte, error) {
	return c.abi.Pack("setStrategyRegistry", in.StrategyRegistry)
}

func (c *Codec) EncodeSetSupportedProtocolMethodCall(in SetSupportedProtocolInput) ([]byte, error) {
	return c.abi.Pack("setSupportedProtocol", in.ProtocolId, in.IsSupported)
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

func (c *Codec) EncodeUnpauseMethodCall() ([]byte, error) {
	return c.abi.Pack("unpause")
}

func (c *Codec) EncodeWithdrawFeesMethodCall(in WithdrawFeesInput) ([]byte, error) {
	return c.abi.Pack("withdrawFees", in.FeeToken)
}

func (c *Codec) EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "messageId", Type: "bytes32"},
			{Name: "sourceChainSelector", Type: "uint64"},
			{Name: "sender", Type: "bytes"},
			{Name: "data", Type: "bytes"},
			{Name: "destTokenAmounts", Type: "(address,uint256)[]"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for ClientAny2EVMMessage: %w", err)
	}
	args := abi.Arguments{
		{Name: "clientAny2EVMMessage", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "token", Type: "address"},
			{Name: "amount", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for ClientEVMTokenAmount: %w", err)
	}
	args := abi.Arguments{
		{Name: "clientEVMTokenAmount", Type: tupleType},
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

func (c *Codec) ActiveStrategyAdapterUpdatedLogHash() []byte {
	return c.abi.Events["ActiveStrategyAdapterUpdated"].ID.Bytes()
}

func (c *Codec) EncodeActiveStrategyAdapterUpdatedTopics(
	evt abi.Event,
	values []ActiveStrategyAdapterUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var activeStrategyAdapterRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ActiveStrategyAdapter).IsZero() {
			activeStrategyAdapterRule = append(activeStrategyAdapterRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ActiveStrategyAdapter)
		if err != nil {
			return nil, err
		}
		activeStrategyAdapterRule = append(activeStrategyAdapterRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		activeStrategyAdapterRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeActiveStrategyAdapterUpdated decodes a log into a ActiveStrategyAdapterUpdated struct.
func (c *Codec) DecodeActiveStrategyAdapterUpdated(log *evm.Log) (*ActiveStrategyAdapterUpdatedDecoded, error) {
	event := new(ActiveStrategyAdapterUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ActiveStrategyAdapterUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ActiveStrategyAdapterUpdated"].Inputs {
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

func (c *Codec) AllowedChainSetLogHash() []byte {
	return c.abi.Events["AllowedChainSet"].ID.Bytes()
}

func (c *Codec) EncodeAllowedChainSetTopics(
	evt abi.Event,
	values []AllowedChainSetTopics,
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
	var isAllowedRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.IsAllowed).IsZero() {
			isAllowedRule = append(isAllowedRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.IsAllowed)
		if err != nil {
			return nil, err
		}
		isAllowedRule = append(isAllowedRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		isAllowedRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeAllowedChainSet decodes a log into a AllowedChainSet struct.
func (c *Codec) DecodeAllowedChainSet(log *evm.Log) (*AllowedChainSetDecoded, error) {
	event := new(AllowedChainSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "AllowedChainSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["AllowedChainSet"].Inputs {
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

func (c *Codec) AllowedPeerSetLogHash() []byte {
	return c.abi.Events["AllowedPeerSet"].ID.Bytes()
}

func (c *Codec) EncodeAllowedPeerSetTopics(
	evt abi.Event,
	values []AllowedPeerSetTopics,
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
	var peerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Peer).IsZero() {
			peerRule = append(peerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Peer)
		if err != nil {
			return nil, err
		}
		peerRule = append(peerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		peerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeAllowedPeerSet decodes a log into a AllowedPeerSet struct.
func (c *Codec) DecodeAllowedPeerSet(log *evm.Log) (*AllowedPeerSetDecoded, error) {
	event := new(AllowedPeerSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "AllowedPeerSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["AllowedPeerSet"].Inputs {
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

func (c *Codec) CCIPGasLimitSetLogHash() []byte {
	return c.abi.Events["CCIPGasLimitSet"].ID.Bytes()
}

func (c *Codec) EncodeCCIPGasLimitSetTopics(
	evt abi.Event,
	values []CCIPGasLimitSetTopics,
) ([]*evm.TopicValues, error) {
	var gasLimitRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.GasLimit).IsZero() {
			gasLimitRule = append(gasLimitRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.GasLimit)
		if err != nil {
			return nil, err
		}
		gasLimitRule = append(gasLimitRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		gasLimitRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCCIPGasLimitSet decodes a log into a CCIPGasLimitSet struct.
func (c *Codec) DecodeCCIPGasLimitSet(log *evm.Log) (*CCIPGasLimitSetDecoded, error) {
	event := new(CCIPGasLimitSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CCIPGasLimitSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CCIPGasLimitSet"].Inputs {
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

func (c *Codec) CCIPMessageReceivedLogHash() []byte {
	return c.abi.Events["CCIPMessageReceived"].ID.Bytes()
}

func (c *Codec) EncodeCCIPMessageReceivedTopics(
	evt abi.Event,
	values []CCIPMessageReceivedTopics,
) ([]*evm.TopicValues, error) {
	var messageIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.MessageId).IsZero() {
			messageIdRule = append(messageIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.MessageId)
		if err != nil {
			return nil, err
		}
		messageIdRule = append(messageIdRule, fieldVal)
	}
	var txTypeRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.TxType).IsZero() {
			txTypeRule = append(txTypeRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.TxType)
		if err != nil {
			return nil, err
		}
		txTypeRule = append(txTypeRule, fieldVal)
	}
	var sourceChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.SourceChainSelector).IsZero() {
			sourceChainSelectorRule = append(sourceChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.SourceChainSelector)
		if err != nil {
			return nil, err
		}
		sourceChainSelectorRule = append(sourceChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		messageIdRule,
		txTypeRule,
		sourceChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCCIPMessageReceived decodes a log into a CCIPMessageReceived struct.
func (c *Codec) DecodeCCIPMessageReceived(log *evm.Log) (*CCIPMessageReceivedDecoded, error) {
	event := new(CCIPMessageReceivedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CCIPMessageReceived", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CCIPMessageReceived"].Inputs {
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

func (c *Codec) CCIPMessageSentLogHash() []byte {
	return c.abi.Events["CCIPMessageSent"].ID.Bytes()
}

func (c *Codec) EncodeCCIPMessageSentTopics(
	evt abi.Event,
	values []CCIPMessageSentTopics,
) ([]*evm.TopicValues, error) {
	var messageIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.MessageId).IsZero() {
			messageIdRule = append(messageIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.MessageId)
		if err != nil {
			return nil, err
		}
		messageIdRule = append(messageIdRule, fieldVal)
	}
	var txTypeRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.TxType).IsZero() {
			txTypeRule = append(txTypeRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.TxType)
		if err != nil {
			return nil, err
		}
		txTypeRule = append(txTypeRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		messageIdRule,
		txTypeRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCCIPMessageSent decodes a log into a CCIPMessageSent struct.
func (c *Codec) DecodeCCIPMessageSent(log *evm.Log) (*CCIPMessageSentDecoded, error) {
	event := new(CCIPMessageSentDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CCIPMessageSent", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CCIPMessageSent"].Inputs {
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

func (c *Codec) DefaultAdminDelayChangeCanceledLogHash() []byte {
	return c.abi.Events["DefaultAdminDelayChangeCanceled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminDelayChangeCanceledTopics(
	evt abi.Event,
	values []DefaultAdminDelayChangeCanceledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminDelayChangeCanceled decodes a log into a DefaultAdminDelayChangeCanceled struct.
func (c *Codec) DecodeDefaultAdminDelayChangeCanceled(log *evm.Log) (*DefaultAdminDelayChangeCanceledDecoded, error) {
	event := new(DefaultAdminDelayChangeCanceledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminDelayChangeCanceled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminDelayChangeCanceled"].Inputs {
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

func (c *Codec) DefaultAdminDelayChangeScheduledLogHash() []byte {
	return c.abi.Events["DefaultAdminDelayChangeScheduled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminDelayChangeScheduledTopics(
	evt abi.Event,
	values []DefaultAdminDelayChangeScheduledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminDelayChangeScheduled decodes a log into a DefaultAdminDelayChangeScheduled struct.
func (c *Codec) DecodeDefaultAdminDelayChangeScheduled(log *evm.Log) (*DefaultAdminDelayChangeScheduledDecoded, error) {
	event := new(DefaultAdminDelayChangeScheduledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminDelayChangeScheduled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminDelayChangeScheduled"].Inputs {
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

func (c *Codec) DefaultAdminTransferCanceledLogHash() []byte {
	return c.abi.Events["DefaultAdminTransferCanceled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminTransferCanceledTopics(
	evt abi.Event,
	values []DefaultAdminTransferCanceledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminTransferCanceled decodes a log into a DefaultAdminTransferCanceled struct.
func (c *Codec) DecodeDefaultAdminTransferCanceled(log *evm.Log) (*DefaultAdminTransferCanceledDecoded, error) {
	event := new(DefaultAdminTransferCanceledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminTransferCanceled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminTransferCanceled"].Inputs {
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

func (c *Codec) DefaultAdminTransferScheduledLogHash() []byte {
	return c.abi.Events["DefaultAdminTransferScheduled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminTransferScheduledTopics(
	evt abi.Event,
	values []DefaultAdminTransferScheduledTopics,
) ([]*evm.TopicValues, error) {
	var newAdminRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAdmin).IsZero() {
			newAdminRule = append(newAdminRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.NewAdmin)
		if err != nil {
			return nil, err
		}
		newAdminRule = append(newAdminRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		newAdminRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminTransferScheduled decodes a log into a DefaultAdminTransferScheduled struct.
func (c *Codec) DecodeDefaultAdminTransferScheduled(log *evm.Log) (*DefaultAdminTransferScheduledDecoded, error) {
	event := new(DefaultAdminTransferScheduledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminTransferScheduled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminTransferScheduled"].Inputs {
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

func (c *Codec) DepositForwardedToStrategyLogHash() []byte {
	return c.abi.Events["DepositForwardedToStrategy"].ID.Bytes()
}

func (c *Codec) EncodeDepositForwardedToStrategyTopics(
	evt abi.Event,
	values []DepositForwardedToStrategyTopics,
) ([]*evm.TopicValues, error) {
	var depositAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.DepositAmount).IsZero() {
			depositAmountRule = append(depositAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.DepositAmount)
		if err != nil {
			return nil, err
		}
		depositAmountRule = append(depositAmountRule, fieldVal)
	}
	var strategyChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.StrategyChainSelector).IsZero() {
			strategyChainSelectorRule = append(strategyChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.StrategyChainSelector)
		if err != nil {
			return nil, err
		}
		strategyChainSelectorRule = append(strategyChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		depositAmountRule,
		strategyChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositForwardedToStrategy decodes a log into a DepositForwardedToStrategy struct.
func (c *Codec) DecodeDepositForwardedToStrategy(log *evm.Log) (*DepositForwardedToStrategyDecoded, error) {
	event := new(DepositForwardedToStrategyDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositForwardedToStrategy", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositForwardedToStrategy"].Inputs {
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

func (c *Codec) DepositInitiatedLogHash() []byte {
	return c.abi.Events["DepositInitiated"].ID.Bytes()
}

func (c *Codec) EncodeDepositInitiatedTopics(
	evt abi.Event,
	values []DepositInitiatedTopics,
) ([]*evm.TopicValues, error) {
	var depositorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Depositor).IsZero() {
			depositorRule = append(depositorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Depositor)
		if err != nil {
			return nil, err
		}
		depositorRule = append(depositorRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}
	var thisChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ThisChainSelector).IsZero() {
			thisChainSelectorRule = append(thisChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ThisChainSelector)
		if err != nil {
			return nil, err
		}
		thisChainSelectorRule = append(thisChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		depositorRule,
		amountRule,
		thisChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositInitiated decodes a log into a DepositInitiated struct.
func (c *Codec) DecodeDepositInitiated(log *evm.Log) (*DepositInitiatedDecoded, error) {
	event := new(DepositInitiatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositInitiated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositInitiated"].Inputs {
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

func (c *Codec) DepositPingPongToChildLogHash() []byte {
	return c.abi.Events["DepositPingPongToChild"].ID.Bytes()
}

func (c *Codec) EncodeDepositPingPongToChildTopics(
	evt abi.Event,
	values []DepositPingPongToChildTopics,
) ([]*evm.TopicValues, error) {
	var depositAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.DepositAmount).IsZero() {
			depositAmountRule = append(depositAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.DepositAmount)
		if err != nil {
			return nil, err
		}
		depositAmountRule = append(depositAmountRule, fieldVal)
	}
	var destChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.DestChainSelector).IsZero() {
			destChainSelectorRule = append(destChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.DestChainSelector)
		if err != nil {
			return nil, err
		}
		destChainSelectorRule = append(destChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		depositAmountRule,
		destChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositPingPongToChild decodes a log into a DepositPingPongToChild struct.
func (c *Codec) DecodeDepositPingPongToChild(log *evm.Log) (*DepositPingPongToChildDecoded, error) {
	event := new(DepositPingPongToChildDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositPingPongToChild", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositPingPongToChild"].Inputs {
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

func (c *Codec) DepositToStrategyLogHash() []byte {
	return c.abi.Events["DepositToStrategy"].ID.Bytes()
}

func (c *Codec) EncodeDepositToStrategyTopics(
	evt abi.Event,
	values []DepositToStrategyTopics,
) ([]*evm.TopicValues, error) {
	var strategyAdapterRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.StrategyAdapter).IsZero() {
			strategyAdapterRule = append(strategyAdapterRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.StrategyAdapter)
		if err != nil {
			return nil, err
		}
		strategyAdapterRule = append(strategyAdapterRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		strategyAdapterRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositToStrategy decodes a log into a DepositToStrategy struct.
func (c *Codec) DecodeDepositToStrategy(log *evm.Log) (*DepositToStrategyDecoded, error) {
	event := new(DepositToStrategyDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositToStrategy", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositToStrategy"].Inputs {
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

func (c *Codec) FeeRateSetLogHash() []byte {
	return c.abi.Events["FeeRateSet"].ID.Bytes()
}

func (c *Codec) EncodeFeeRateSetTopics(
	evt abi.Event,
	values []FeeRateSetTopics,
) ([]*evm.TopicValues, error) {
	var feeRateRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeeRate).IsZero() {
			feeRateRule = append(feeRateRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.FeeRate)
		if err != nil {
			return nil, err
		}
		feeRateRule = append(feeRateRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		feeRateRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeFeeRateSet decodes a log into a FeeRateSet struct.
func (c *Codec) DecodeFeeRateSet(log *evm.Log) (*FeeRateSetDecoded, error) {
	event := new(FeeRateSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "FeeRateSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["FeeRateSet"].Inputs {
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

func (c *Codec) FeeTakenLogHash() []byte {
	return c.abi.Events["FeeTaken"].ID.Bytes()
}

func (c *Codec) EncodeFeeTakenTopics(
	evt abi.Event,
	values []FeeTakenTopics,
) ([]*evm.TopicValues, error) {
	var feeAmountInStablecoinRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeeAmountInStablecoin).IsZero() {
			feeAmountInStablecoinRule = append(feeAmountInStablecoinRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.FeeAmountInStablecoin)
		if err != nil {
			return nil, err
		}
		feeAmountInStablecoinRule = append(feeAmountInStablecoinRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		feeAmountInStablecoinRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeFeeTaken decodes a log into a FeeTaken struct.
func (c *Codec) DecodeFeeTaken(log *evm.Log) (*FeeTakenDecoded, error) {
	event := new(FeeTakenDecoded)
	if err := c.abi.UnpackIntoInterface(event, "FeeTaken", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["FeeTaken"].Inputs {
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

func (c *Codec) FeesWithdrawnLogHash() []byte {
	return c.abi.Events["FeesWithdrawn"].ID.Bytes()
}

func (c *Codec) EncodeFeesWithdrawnTopics(
	evt abi.Event,
	values []FeesWithdrawnTopics,
) ([]*evm.TopicValues, error) {
	var feesWithdrawnRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeesWithdrawn).IsZero() {
			feesWithdrawnRule = append(feesWithdrawnRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.FeesWithdrawn)
		if err != nil {
			return nil, err
		}
		feesWithdrawnRule = append(feesWithdrawnRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		feesWithdrawnRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeFeesWithdrawn decodes a log into a FeesWithdrawn struct.
func (c *Codec) DecodeFeesWithdrawn(log *evm.Log) (*FeesWithdrawnDecoded, error) {
	event := new(FeesWithdrawnDecoded)
	if err := c.abi.UnpackIntoInterface(event, "FeesWithdrawn", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["FeesWithdrawn"].Inputs {
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

func (c *Codec) PausedLogHash() []byte {
	return c.abi.Events["Paused"].ID.Bytes()
}

func (c *Codec) EncodePausedTopics(
	evt abi.Event,
	values []PausedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePaused decodes a log into a Paused struct.
func (c *Codec) DecodePaused(log *evm.Log) (*PausedDecoded, error) {
	event := new(PausedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Paused", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Paused"].Inputs {
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

func (c *Codec) RebalancerSetLogHash() []byte {
	return c.abi.Events["RebalancerSet"].ID.Bytes()
}

func (c *Codec) EncodeRebalancerSetTopics(
	evt abi.Event,
	values []RebalancerSetTopics,
) ([]*evm.TopicValues, error) {
	var rebalancerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Rebalancer).IsZero() {
			rebalancerRule = append(rebalancerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Rebalancer)
		if err != nil {
			return nil, err
		}
		rebalancerRule = append(rebalancerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalancerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalancerSet decodes a log into a RebalancerSet struct.
func (c *Codec) DecodeRebalancerSet(log *evm.Log) (*RebalancerSetDecoded, error) {
	event := new(RebalancerSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalancerSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalancerSet"].Inputs {
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

func (c *Codec) RoleAdminChangedLogHash() []byte {
	return c.abi.Events["RoleAdminChanged"].ID.Bytes()
}

func (c *Codec) EncodeRoleAdminChangedTopics(
	evt abi.Event,
	values []RoleAdminChangedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var previousAdminRoleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousAdminRole).IsZero() {
			previousAdminRoleRule = append(previousAdminRoleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.PreviousAdminRole)
		if err != nil {
			return nil, err
		}
		previousAdminRoleRule = append(previousAdminRoleRule, fieldVal)
	}
	var newAdminRoleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAdminRole).IsZero() {
			newAdminRoleRule = append(newAdminRoleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.NewAdminRole)
		if err != nil {
			return nil, err
		}
		newAdminRoleRule = append(newAdminRoleRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		previousAdminRoleRule,
		newAdminRoleRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleAdminChanged decodes a log into a RoleAdminChanged struct.
func (c *Codec) DecodeRoleAdminChanged(log *evm.Log) (*RoleAdminChangedDecoded, error) {
	event := new(RoleAdminChangedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleAdminChanged", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleAdminChanged"].Inputs {
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

func (c *Codec) RoleGrantedLogHash() []byte {
	return c.abi.Events["RoleGranted"].ID.Bytes()
}

func (c *Codec) EncodeRoleGrantedTopics(
	evt abi.Event,
	values []RoleGrantedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var accountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Account).IsZero() {
			accountRule = append(accountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Account)
		if err != nil {
			return nil, err
		}
		accountRule = append(accountRule, fieldVal)
	}
	var senderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Sender).IsZero() {
			senderRule = append(senderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Sender)
		if err != nil {
			return nil, err
		}
		senderRule = append(senderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		accountRule,
		senderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleGranted decodes a log into a RoleGranted struct.
func (c *Codec) DecodeRoleGranted(log *evm.Log) (*RoleGrantedDecoded, error) {
	event := new(RoleGrantedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleGranted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleGranted"].Inputs {
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

func (c *Codec) RoleRevokedLogHash() []byte {
	return c.abi.Events["RoleRevoked"].ID.Bytes()
}

func (c *Codec) EncodeRoleRevokedTopics(
	evt abi.Event,
	values []RoleRevokedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var accountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Account).IsZero() {
			accountRule = append(accountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Account)
		if err != nil {
			return nil, err
		}
		accountRule = append(accountRule, fieldVal)
	}
	var senderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Sender).IsZero() {
			senderRule = append(senderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Sender)
		if err != nil {
			return nil, err
		}
		senderRule = append(senderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		accountRule,
		senderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleRevoked decodes a log into a RoleRevoked struct.
func (c *Codec) DecodeRoleRevoked(log *evm.Log) (*RoleRevokedDecoded, error) {
	event := new(RoleRevokedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleRevoked", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleRevoked"].Inputs {
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

func (c *Codec) ShareBurnUpdateLogHash() []byte {
	return c.abi.Events["ShareBurnUpdate"].ID.Bytes()
}

func (c *Codec) EncodeShareBurnUpdateTopics(
	evt abi.Event,
	values []ShareBurnUpdateTopics,
) ([]*evm.TopicValues, error) {
	var shareBurnAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareBurnAmount).IsZero() {
			shareBurnAmountRule = append(shareBurnAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ShareBurnAmount)
		if err != nil {
			return nil, err
		}
		shareBurnAmountRule = append(shareBurnAmountRule, fieldVal)
	}
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var totalSharesRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.TotalShares).IsZero() {
			totalSharesRule = append(totalSharesRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.TotalShares)
		if err != nil {
			return nil, err
		}
		totalSharesRule = append(totalSharesRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		shareBurnAmountRule,
		chainSelectorRule,
		totalSharesRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeShareBurnUpdate decodes a log into a ShareBurnUpdate struct.
func (c *Codec) DecodeShareBurnUpdate(log *evm.Log) (*ShareBurnUpdateDecoded, error) {
	event := new(ShareBurnUpdateDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ShareBurnUpdate", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ShareBurnUpdate"].Inputs {
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

func (c *Codec) ShareMintUpdateLogHash() []byte {
	return c.abi.Events["ShareMintUpdate"].ID.Bytes()
}

func (c *Codec) EncodeShareMintUpdateTopics(
	evt abi.Event,
	values []ShareMintUpdateTopics,
) ([]*evm.TopicValues, error) {
	var shareMintAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareMintAmount).IsZero() {
			shareMintAmountRule = append(shareMintAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ShareMintAmount)
		if err != nil {
			return nil, err
		}
		shareMintAmountRule = append(shareMintAmountRule, fieldVal)
	}
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var totalSharesRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.TotalShares).IsZero() {
			totalSharesRule = append(totalSharesRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.TotalShares)
		if err != nil {
			return nil, err
		}
		totalSharesRule = append(totalSharesRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		shareMintAmountRule,
		chainSelectorRule,
		totalSharesRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeShareMintUpdate decodes a log into a ShareMintUpdate struct.
func (c *Codec) DecodeShareMintUpdate(log *evm.Log) (*ShareMintUpdateDecoded, error) {
	event := new(ShareMintUpdateDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ShareMintUpdate", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ShareMintUpdate"].Inputs {
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

func (c *Codec) SharesBurnedLogHash() []byte {
	return c.abi.Events["SharesBurned"].ID.Bytes()
}

func (c *Codec) EncodeSharesBurnedTopics(
	evt abi.Event,
	values []SharesBurnedTopics,
) ([]*evm.TopicValues, error) {
	var fromRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.From).IsZero() {
			fromRule = append(fromRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.From)
		if err != nil {
			return nil, err
		}
		fromRule = append(fromRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		fromRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeSharesBurned decodes a log into a SharesBurned struct.
func (c *Codec) DecodeSharesBurned(log *evm.Log) (*SharesBurnedDecoded, error) {
	event := new(SharesBurnedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "SharesBurned", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["SharesBurned"].Inputs {
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

func (c *Codec) SharesMintedLogHash() []byte {
	return c.abi.Events["SharesMinted"].ID.Bytes()
}

func (c *Codec) EncodeSharesMintedTopics(
	evt abi.Event,
	values []SharesMintedTopics,
) ([]*evm.TopicValues, error) {
	var toRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.To).IsZero() {
			toRule = append(toRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.To)
		if err != nil {
			return nil, err
		}
		toRule = append(toRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		toRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeSharesMinted decodes a log into a SharesMinted struct.
func (c *Codec) DecodeSharesMinted(log *evm.Log) (*SharesMintedDecoded, error) {
	event := new(SharesMintedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "SharesMinted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["SharesMinted"].Inputs {
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

func (c *Codec) StrategyUpdatedLogHash() []byte {
	return c.abi.Events["StrategyUpdated"].ID.Bytes()
}

func (c *Codec) EncodeStrategyUpdatedTopics(
	evt abi.Event,
	values []StrategyUpdatedTopics,
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
	var oldChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.OldChainSelector).IsZero() {
			oldChainSelectorRule = append(oldChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.OldChainSelector)
		if err != nil {
			return nil, err
		}
		oldChainSelectorRule = append(oldChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		protocolIdRule,
		oldChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeStrategyUpdated decodes a log into a StrategyUpdated struct.
func (c *Codec) DecodeStrategyUpdated(log *evm.Log) (*StrategyUpdatedDecoded, error) {
	event := new(StrategyUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "StrategyUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["StrategyUpdated"].Inputs {
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

func (c *Codec) SupportedProtocolSetLogHash() []byte {
	return c.abi.Events["SupportedProtocolSet"].ID.Bytes()
}

func (c *Codec) EncodeSupportedProtocolSetTopics(
	evt abi.Event,
	values []SupportedProtocolSetTopics,
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
	var isSupportedRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.IsSupported).IsZero() {
			isSupportedRule = append(isSupportedRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.IsSupported)
		if err != nil {
			return nil, err
		}
		isSupportedRule = append(isSupportedRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		protocolIdRule,
		isSupportedRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeSupportedProtocolSet decodes a log into a SupportedProtocolSet struct.
func (c *Codec) DecodeSupportedProtocolSet(log *evm.Log) (*SupportedProtocolSetDecoded, error) {
	event := new(SupportedProtocolSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "SupportedProtocolSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["SupportedProtocolSet"].Inputs {
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

func (c *Codec) UnpausedLogHash() []byte {
	return c.abi.Events["Unpaused"].ID.Bytes()
}

func (c *Codec) EncodeUnpausedTopics(
	evt abi.Event,
	values []UnpausedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeUnpaused decodes a log into a Unpaused struct.
func (c *Codec) DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error) {
	event := new(UnpausedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Unpaused", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Unpaused"].Inputs {
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

func (c *Codec) WithdrawCompletedLogHash() []byte {
	return c.abi.Events["WithdrawCompleted"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawCompletedTopics(
	evt abi.Event,
	values []WithdrawCompletedTopics,
) ([]*evm.TopicValues, error) {
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		withdrawerRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawCompleted decodes a log into a WithdrawCompleted struct.
func (c *Codec) DecodeWithdrawCompleted(log *evm.Log) (*WithdrawCompletedDecoded, error) {
	event := new(WithdrawCompletedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawCompleted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawCompleted"].Inputs {
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

func (c *Codec) WithdrawForwardedToStrategyLogHash() []byte {
	return c.abi.Events["WithdrawForwardedToStrategy"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawForwardedToStrategyTopics(
	evt abi.Event,
	values []WithdrawForwardedToStrategyTopics,
) ([]*evm.TopicValues, error) {
	var shareBurnAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareBurnAmount).IsZero() {
			shareBurnAmountRule = append(shareBurnAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ShareBurnAmount)
		if err != nil {
			return nil, err
		}
		shareBurnAmountRule = append(shareBurnAmountRule, fieldVal)
	}
	var strategyChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.StrategyChainSelector).IsZero() {
			strategyChainSelectorRule = append(strategyChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.StrategyChainSelector)
		if err != nil {
			return nil, err
		}
		strategyChainSelectorRule = append(strategyChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		shareBurnAmountRule,
		strategyChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawForwardedToStrategy decodes a log into a WithdrawForwardedToStrategy struct.
func (c *Codec) DecodeWithdrawForwardedToStrategy(log *evm.Log) (*WithdrawForwardedToStrategyDecoded, error) {
	event := new(WithdrawForwardedToStrategyDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawForwardedToStrategy", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawForwardedToStrategy"].Inputs {
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

func (c *Codec) WithdrawFromStrategyLogHash() []byte {
	return c.abi.Events["WithdrawFromStrategy"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawFromStrategyTopics(
	evt abi.Event,
	values []WithdrawFromStrategyTopics,
) ([]*evm.TopicValues, error) {
	var strategyAdapterRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.StrategyAdapter).IsZero() {
			strategyAdapterRule = append(strategyAdapterRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.StrategyAdapter)
		if err != nil {
			return nil, err
		}
		strategyAdapterRule = append(strategyAdapterRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		strategyAdapterRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawFromStrategy decodes a log into a WithdrawFromStrategy struct.
func (c *Codec) DecodeWithdrawFromStrategy(log *evm.Log) (*WithdrawFromStrategyDecoded, error) {
	event := new(WithdrawFromStrategyDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawFromStrategy", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawFromStrategy"].Inputs {
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

func (c *Codec) WithdrawInitiatedLogHash() []byte {
	return c.abi.Events["WithdrawInitiated"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawInitiatedTopics(
	evt abi.Event,
	values []WithdrawInitiatedTopics,
) ([]*evm.TopicValues, error) {
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}
	var thisChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ThisChainSelector).IsZero() {
			thisChainSelectorRule = append(thisChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ThisChainSelector)
		if err != nil {
			return nil, err
		}
		thisChainSelectorRule = append(thisChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		withdrawerRule,
		amountRule,
		thisChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawInitiated decodes a log into a WithdrawInitiated struct.
func (c *Codec) DecodeWithdrawInitiated(log *evm.Log) (*WithdrawInitiatedDecoded, error) {
	event := new(WithdrawInitiatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawInitiated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawInitiated"].Inputs {
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

func (c *Codec) WithdrawPingPongToChildLogHash() []byte {
	return c.abi.Events["WithdrawPingPongToChild"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawPingPongToChildTopics(
	evt abi.Event,
	values []WithdrawPingPongToChildTopics,
) ([]*evm.TopicValues, error) {
	var shareBurnAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareBurnAmount).IsZero() {
			shareBurnAmountRule = append(shareBurnAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ShareBurnAmount)
		if err != nil {
			return nil, err
		}
		shareBurnAmountRule = append(shareBurnAmountRule, fieldVal)
	}
	var destChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.DestChainSelector).IsZero() {
			destChainSelectorRule = append(destChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.DestChainSelector)
		if err != nil {
			return nil, err
		}
		destChainSelectorRule = append(destChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		shareBurnAmountRule,
		destChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawPingPongToChild decodes a log into a WithdrawPingPongToChild struct.
func (c *Codec) DecodeWithdrawPingPongToChild(log *evm.Log) (*WithdrawPingPongToChildDecoded, error) {
	event := new(WithdrawPingPongToChildDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawPingPongToChild", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawPingPongToChild"].Inputs {
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

func (c ParentPeer) DEFAULTADMINROLE(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[32]byte] {
	calldata, err := c.Codec.EncodeDEFAULTADMINROLEMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[32]byte](*new([32]byte), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeDEFAULTADMINROLEMethodOutput(response.Data)
	})

}

func (c ParentPeer) DefaultAdmin(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeDefaultAdminMethodCall()
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
		return c.Codec.DecodeDefaultAdminMethodOutput(response.Data)
	})

}

func (c ParentPeer) DefaultAdminDelay(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeDefaultAdminDelayMethodCall()
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
		return c.Codec.DecodeDefaultAdminDelayMethodOutput(response.Data)
	})

}

func (c ParentPeer) DefaultAdminDelayIncreaseWait(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeDefaultAdminDelayIncreaseWaitMethodCall()
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
		return c.Codec.DecodeDefaultAdminDelayIncreaseWaitMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetActiveStrategyAdapter(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetActiveStrategyAdapterMethodCall()
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
		return c.Codec.DecodeGetActiveStrategyAdapterMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetAllowedChain(
	runtime cre.Runtime,
	args GetAllowedChainInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetAllowedChainMethodCall(args)
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
		return c.Codec.DecodeGetAllowedChainMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetAllowedPeer(
	runtime cre.Runtime,
	args GetAllowedPeerInput,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetAllowedPeerMethodCall(args)
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
		return c.Codec.DecodeGetAllowedPeerMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetCCIPGasLimit(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetCCIPGasLimitMethodCall()
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
		return c.Codec.DecodeGetCCIPGasLimitMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetFeeRate(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetFeeRateMethodCall()
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
		return c.Codec.DecodeGetFeeRateMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetIsStrategyChain(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetIsStrategyChainMethodCall()
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
		return c.Codec.DecodeGetIsStrategyChainMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetLink(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetLinkMethodCall()
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
		return c.Codec.DecodeGetLinkMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetRebalancer(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetRebalancerMethodCall()
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
		return c.Codec.DecodeGetRebalancerMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetRoleAdmin(
	runtime cre.Runtime,
	args GetRoleAdminInput,
	blockNumber *big.Int,
) cre.Promise[[32]byte] {
	calldata, err := c.Codec.EncodeGetRoleAdminMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[[32]byte](*new([32]byte), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeGetRoleAdminMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetRouter(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetRouterMethodCall()
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
		return c.Codec.DecodeGetRouterMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetShare(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetShareMethodCall()
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
		return c.Codec.DecodeGetShareMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetStrategy(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[IYieldPeerStrategy] {
	calldata, err := c.Codec.EncodeGetStrategyMethodCall()
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
		return c.Codec.DecodeGetStrategyMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetStrategyAdapter(
	runtime cre.Runtime,
	args GetStrategyAdapterInput,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetStrategyAdapterMethodCall(args)
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
		return c.Codec.DecodeGetStrategyAdapterMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetStrategyRegistry(
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

func (c ParentPeer) GetSupportedProtocol(
	runtime cre.Runtime,
	args GetSupportedProtocolInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetSupportedProtocolMethodCall(args)
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
		return c.Codec.DecodeGetSupportedProtocolMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetThisChainSelector(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[uint64] {
	calldata, err := c.Codec.EncodeGetThisChainSelectorMethodCall()
	if err != nil {
		return cre.PromiseFromResult[uint64](*new(uint64), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (uint64, error) {
		return c.Codec.DecodeGetThisChainSelectorMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetTotalShares(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetTotalSharesMethodCall()
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
		return c.Codec.DecodeGetTotalSharesMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetTotalValue(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetTotalValueMethodCall()
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
		return c.Codec.DecodeGetTotalValueMethodOutput(response.Data)
	})

}

func (c ParentPeer) GetUsdc(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetUsdcMethodCall()
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
		return c.Codec.DecodeGetUsdcMethodOutput(response.Data)
	})

}

func (c ParentPeer) HasRole(
	runtime cre.Runtime,
	args HasRoleInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeHasRoleMethodCall(args)
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
		return c.Codec.DecodeHasRoleMethodOutput(response.Data)
	})

}

func (c ParentPeer) Owner(
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

func (c ParentPeer) Paused(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodePausedMethodCall()
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
		return c.Codec.DecodePausedMethodOutput(response.Data)
	})

}

func (c ParentPeer) PendingDefaultAdmin(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[PendingDefaultAdminOutput] {
	calldata, err := c.Codec.EncodePendingDefaultAdminMethodCall()
	if err != nil {
		return cre.PromiseFromResult[PendingDefaultAdminOutput](PendingDefaultAdminOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (PendingDefaultAdminOutput, error) {
		return c.Codec.DecodePendingDefaultAdminMethodOutput(response.Data)
	})

}

func (c ParentPeer) PendingDefaultAdminDelay(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[PendingDefaultAdminDelayOutput] {
	calldata, err := c.Codec.EncodePendingDefaultAdminDelayMethodCall()
	if err != nil {
		return cre.PromiseFromResult[PendingDefaultAdminDelayOutput](PendingDefaultAdminDelayOutput{}, err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (PendingDefaultAdminDelayOutput, error) {
		return c.Codec.DecodePendingDefaultAdminDelayMethodOutput(response.Data)
	})

}

func (c ParentPeer) SupportsInterface(
	runtime cre.Runtime,
	args SupportsInterfaceInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeSupportsInterfaceMethodCall(args)
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
		return c.Codec.DecodeSupportsInterfaceMethodOutput(response.Data)
	})

}

func (c ParentPeer) WriteReportFromClientAny2EVMMessage(
	runtime cre.Runtime,
	input ClientAny2EVMMessage,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeClientAny2EVMMessageStruct(input)
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

func (c ParentPeer) WriteReportFromClientEVMTokenAmount(
	runtime cre.Runtime,
	input ClientEVMTokenAmount,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeClientEVMTokenAmountStruct(input)
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

func (c ParentPeer) WriteReportFromIYieldPeerStrategy(
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

func (c ParentPeer) WriteReport(
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

// DecodeAccessControlBadConfirmationError decodes a AccessControlBadConfirmation error from revert data.
func (c *ParentPeer) DecodeAccessControlBadConfirmationError(data []byte) (*AccessControlBadConfirmation, error) {
	args := c.ABI.Errors["AccessControlBadConfirmation"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &AccessControlBadConfirmation{}, nil
}

// Error implements the error interface for AccessControlBadConfirmation.
func (e *AccessControlBadConfirmation) Error() string {
	return fmt.Sprintf("AccessControlBadConfirmation error:")
}

// DecodeAccessControlEnforcedDefaultAdminDelayError decodes a AccessControlEnforcedDefaultAdminDelay error from revert data.
func (c *ParentPeer) DecodeAccessControlEnforcedDefaultAdminDelayError(data []byte) (*AccessControlEnforcedDefaultAdminDelay, error) {
	args := c.ABI.Errors["AccessControlEnforcedDefaultAdminDelay"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	schedule, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for schedule in AccessControlEnforcedDefaultAdminDelay error")
	}

	return &AccessControlEnforcedDefaultAdminDelay{
		Schedule: schedule,
	}, nil
}

// Error implements the error interface for AccessControlEnforcedDefaultAdminDelay.
func (e *AccessControlEnforcedDefaultAdminDelay) Error() string {
	return fmt.Sprintf("AccessControlEnforcedDefaultAdminDelay error: schedule=%v;", e.Schedule)
}

// DecodeAccessControlEnforcedDefaultAdminRulesError decodes a AccessControlEnforcedDefaultAdminRules error from revert data.
func (c *ParentPeer) DecodeAccessControlEnforcedDefaultAdminRulesError(data []byte) (*AccessControlEnforcedDefaultAdminRules, error) {
	args := c.ABI.Errors["AccessControlEnforcedDefaultAdminRules"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &AccessControlEnforcedDefaultAdminRules{}, nil
}

// Error implements the error interface for AccessControlEnforcedDefaultAdminRules.
func (e *AccessControlEnforcedDefaultAdminRules) Error() string {
	return fmt.Sprintf("AccessControlEnforcedDefaultAdminRules error:")
}

// DecodeAccessControlInvalidDefaultAdminError decodes a AccessControlInvalidDefaultAdmin error from revert data.
func (c *ParentPeer) DecodeAccessControlInvalidDefaultAdminError(data []byte) (*AccessControlInvalidDefaultAdmin, error) {
	args := c.ABI.Errors["AccessControlInvalidDefaultAdmin"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	defaultAdmin, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for defaultAdmin in AccessControlInvalidDefaultAdmin error")
	}

	return &AccessControlInvalidDefaultAdmin{
		DefaultAdmin: defaultAdmin,
	}, nil
}

// Error implements the error interface for AccessControlInvalidDefaultAdmin.
func (e *AccessControlInvalidDefaultAdmin) Error() string {
	return fmt.Sprintf("AccessControlInvalidDefaultAdmin error: defaultAdmin=%v;", e.DefaultAdmin)
}

// DecodeAccessControlUnauthorizedAccountError decodes a AccessControlUnauthorizedAccount error from revert data.
func (c *ParentPeer) DecodeAccessControlUnauthorizedAccountError(data []byte) (*AccessControlUnauthorizedAccount, error) {
	args := c.ABI.Errors["AccessControlUnauthorizedAccount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	account, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for account in AccessControlUnauthorizedAccount error")
	}

	neededRole, ok1 := values[1].([32]byte)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for neededRole in AccessControlUnauthorizedAccount error")
	}

	return &AccessControlUnauthorizedAccount{
		Account:    account,
		NeededRole: neededRole,
	}, nil
}

// Error implements the error interface for AccessControlUnauthorizedAccount.
func (e *AccessControlUnauthorizedAccount) Error() string {
	return fmt.Sprintf("AccessControlUnauthorizedAccount error: account=%v; neededRole=%v;", e.Account, e.NeededRole)
}

// DecodeCCIPOperationsInvalidTokenError decodes a CCIPOperations__InvalidToken error from revert data.
func (c *ParentPeer) DecodeCCIPOperationsInvalidTokenError(data []byte) (*CCIPOperationsInvalidToken, error) {
	args := c.ABI.Errors["CCIPOperations__InvalidToken"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	invalidToken, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for invalidToken in CCIPOperationsInvalidToken error")
	}

	return &CCIPOperationsInvalidToken{
		InvalidToken: invalidToken,
	}, nil
}

// Error implements the error interface for CCIPOperationsInvalidToken.
func (e *CCIPOperationsInvalidToken) Error() string {
	return fmt.Sprintf("CCIPOperationsInvalidToken error: invalidToken=%v;", e.InvalidToken)
}

// DecodeCCIPOperationsInvalidTokenAmountError decodes a CCIPOperations__InvalidTokenAmount error from revert data.
func (c *ParentPeer) DecodeCCIPOperationsInvalidTokenAmountError(data []byte) (*CCIPOperationsInvalidTokenAmount, error) {
	args := c.ABI.Errors["CCIPOperations__InvalidTokenAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	invalidAmount, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for invalidAmount in CCIPOperationsInvalidTokenAmount error")
	}

	return &CCIPOperationsInvalidTokenAmount{
		InvalidAmount: invalidAmount,
	}, nil
}

// Error implements the error interface for CCIPOperationsInvalidTokenAmount.
func (e *CCIPOperationsInvalidTokenAmount) Error() string {
	return fmt.Sprintf("CCIPOperationsInvalidTokenAmount error: invalidAmount=%v;", e.InvalidAmount)
}

// DecodeCCIPOperationsNotEnoughLinkError decodes a CCIPOperations__NotEnoughLink error from revert data.
func (c *ParentPeer) DecodeCCIPOperationsNotEnoughLinkError(data []byte) (*CCIPOperationsNotEnoughLink, error) {
	args := c.ABI.Errors["CCIPOperations__NotEnoughLink"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	linkBalance, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for linkBalance in CCIPOperationsNotEnoughLink error")
	}

	fees, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for fees in CCIPOperationsNotEnoughLink error")
	}

	return &CCIPOperationsNotEnoughLink{
		LinkBalance: linkBalance,
		Fees:        fees,
	}, nil
}

// Error implements the error interface for CCIPOperationsNotEnoughLink.
func (e *CCIPOperationsNotEnoughLink) Error() string {
	return fmt.Sprintf("CCIPOperationsNotEnoughLink error: linkBalance=%v; fees=%v;", e.LinkBalance, e.Fees)
}

// DecodeEnforcedPauseError decodes a EnforcedPause error from revert data.
func (c *ParentPeer) DecodeEnforcedPauseError(data []byte) (*EnforcedPause, error) {
	args := c.ABI.Errors["EnforcedPause"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &EnforcedPause{}, nil
}

// Error implements the error interface for EnforcedPause.
func (e *EnforcedPause) Error() string {
	return fmt.Sprintf("EnforcedPause error:")
}

// DecodeExpectedPauseError decodes a ExpectedPause error from revert data.
func (c *ParentPeer) DecodeExpectedPauseError(data []byte) (*ExpectedPause, error) {
	args := c.ABI.Errors["ExpectedPause"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ExpectedPause{}, nil
}

// Error implements the error interface for ExpectedPause.
func (e *ExpectedPause) Error() string {
	return fmt.Sprintf("ExpectedPause error:")
}

// DecodeInvalidRouterError decodes a InvalidRouter error from revert data.
func (c *ParentPeer) DecodeInvalidRouterError(data []byte) (*InvalidRouter, error) {
	args := c.ABI.Errors["InvalidRouter"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	router, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for router in InvalidRouter error")
	}

	return &InvalidRouter{
		Router: router,
	}, nil
}

// Error implements the error interface for InvalidRouter.
func (e *InvalidRouter) Error() string {
	return fmt.Sprintf("InvalidRouter error: router=%v;", e.Router)
}

// DecodeParentPeerCurrentStrategyOptimalError decodes a ParentPeer__CurrentStrategyOptimal error from revert data.
func (c *ParentPeer) DecodeParentPeerCurrentStrategyOptimalError(data []byte) (*ParentPeerCurrentStrategyOptimal, error) {
	args := c.ABI.Errors["ParentPeer__CurrentStrategyOptimal"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentPeerCurrentStrategyOptimal{}, nil
}

// Error implements the error interface for ParentPeerCurrentStrategyOptimal.
func (e *ParentPeerCurrentStrategyOptimal) Error() string {
	return fmt.Sprintf("ParentPeerCurrentStrategyOptimal error:")
}

// DecodeParentPeerInactiveStrategyAdapterError decodes a ParentPeer__InactiveStrategyAdapter error from revert data.
func (c *ParentPeer) DecodeParentPeerInactiveStrategyAdapterError(data []byte) (*ParentPeerInactiveStrategyAdapter, error) {
	args := c.ABI.Errors["ParentPeer__InactiveStrategyAdapter"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentPeerInactiveStrategyAdapter{}, nil
}

// Error implements the error interface for ParentPeerInactiveStrategyAdapter.
func (e *ParentPeerInactiveStrategyAdapter) Error() string {
	return fmt.Sprintf("ParentPeerInactiveStrategyAdapter error:")
}

// DecodeParentPeerInitialActiveStrategyAlreadySetError decodes a ParentPeer__InitialActiveStrategyAlreadySet error from revert data.
func (c *ParentPeer) DecodeParentPeerInitialActiveStrategyAlreadySetError(data []byte) (*ParentPeerInitialActiveStrategyAlreadySet, error) {
	args := c.ABI.Errors["ParentPeer__InitialActiveStrategyAlreadySet"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentPeerInitialActiveStrategyAlreadySet{}, nil
}

// Error implements the error interface for ParentPeerInitialActiveStrategyAlreadySet.
func (e *ParentPeerInitialActiveStrategyAlreadySet) Error() string {
	return fmt.Sprintf("ParentPeerInitialActiveStrategyAlreadySet error:")
}

// DecodeParentPeerOnlyRebalancerError decodes a ParentPeer__OnlyRebalancer error from revert data.
func (c *ParentPeer) DecodeParentPeerOnlyRebalancerError(data []byte) (*ParentPeerOnlyRebalancer, error) {
	args := c.ABI.Errors["ParentPeer__OnlyRebalancer"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentPeerOnlyRebalancer{}, nil
}

// Error implements the error interface for ParentPeerOnlyRebalancer.
func (e *ParentPeerOnlyRebalancer) Error() string {
	return fmt.Sprintf("ParentPeerOnlyRebalancer error:")
}

// DecodeParentPeerStrategyNotSupportedError decodes a ParentPeer__StrategyNotSupported error from revert data.
func (c *ParentPeer) DecodeParentPeerStrategyNotSupportedError(data []byte) (*ParentPeerStrategyNotSupported, error) {
	args := c.ABI.Errors["ParentPeer__StrategyNotSupported"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in ParentPeerStrategyNotSupported error")
	}

	return &ParentPeerStrategyNotSupported{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for ParentPeerStrategyNotSupported.
func (e *ParentPeerStrategyNotSupported) Error() string {
	return fmt.Sprintf("ParentPeerStrategyNotSupported error: protocolId=%v;", e.ProtocolId)
}

// DecodeSafeCastOverflowedUintDowncastError decodes a SafeCastOverflowedUintDowncast error from revert data.
func (c *ParentPeer) DecodeSafeCastOverflowedUintDowncastError(data []byte) (*SafeCastOverflowedUintDowncast, error) {
	args := c.ABI.Errors["SafeCastOverflowedUintDowncast"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	bits, ok0 := values[0].(uint8)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for bits in SafeCastOverflowedUintDowncast error")
	}

	value, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for value in SafeCastOverflowedUintDowncast error")
	}

	return &SafeCastOverflowedUintDowncast{
		Bits:  bits,
		Value: value,
	}, nil
}

// Error implements the error interface for SafeCastOverflowedUintDowncast.
func (e *SafeCastOverflowedUintDowncast) Error() string {
	return fmt.Sprintf("SafeCastOverflowedUintDowncast error: bits=%v; value=%v;", e.Bits, e.Value)
}

// DecodeSafeERC20FailedOperationError decodes a SafeERC20FailedOperation error from revert data.
func (c *ParentPeer) DecodeSafeERC20FailedOperationError(data []byte) (*SafeERC20FailedOperation, error) {
	args := c.ABI.Errors["SafeERC20FailedOperation"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	token, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for token in SafeERC20FailedOperation error")
	}

	return &SafeERC20FailedOperation{
		Token: token,
	}, nil
}

// Error implements the error interface for SafeERC20FailedOperation.
func (e *SafeERC20FailedOperation) Error() string {
	return fmt.Sprintf("SafeERC20FailedOperation error: token=%v;", e.Token)
}

// DecodeYieldFeesFeeRateTooHighError decodes a YieldFees__FeeRateTooHigh error from revert data.
func (c *ParentPeer) DecodeYieldFeesFeeRateTooHighError(data []byte) (*YieldFeesFeeRateTooHigh, error) {
	args := c.ABI.Errors["YieldFees__FeeRateTooHigh"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldFeesFeeRateTooHigh{}, nil
}

// Error implements the error interface for YieldFeesFeeRateTooHigh.
func (e *YieldFeesFeeRateTooHigh) Error() string {
	return fmt.Sprintf("YieldFeesFeeRateTooHigh error:")
}

// DecodeYieldFeesNoFeesToWithdrawError decodes a YieldFees__NoFeesToWithdraw error from revert data.
func (c *ParentPeer) DecodeYieldFeesNoFeesToWithdrawError(data []byte) (*YieldFeesNoFeesToWithdraw, error) {
	args := c.ABI.Errors["YieldFees__NoFeesToWithdraw"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldFeesNoFeesToWithdraw{}, nil
}

// Error implements the error interface for YieldFeesNoFeesToWithdraw.
func (e *YieldFeesNoFeesToWithdraw) Error() string {
	return fmt.Sprintf("YieldFeesNoFeesToWithdraw error:")
}

// DecodeYieldPeerChainNotAllowedError decodes a YieldPeer__ChainNotAllowed error from revert data.
func (c *ParentPeer) DecodeYieldPeerChainNotAllowedError(data []byte) (*YieldPeerChainNotAllowed, error) {
	args := c.ABI.Errors["YieldPeer__ChainNotAllowed"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	chainSelector, ok0 := values[0].(uint64)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for chainSelector in YieldPeerChainNotAllowed error")
	}

	return &YieldPeerChainNotAllowed{
		ChainSelector: chainSelector,
	}, nil
}

// Error implements the error interface for YieldPeerChainNotAllowed.
func (e *YieldPeerChainNotAllowed) Error() string {
	return fmt.Sprintf("YieldPeerChainNotAllowed error: chainSelector=%v;", e.ChainSelector)
}

// DecodeYieldPeerInsufficientAmountError decodes a YieldPeer__InsufficientAmount error from revert data.
func (c *ParentPeer) DecodeYieldPeerInsufficientAmountError(data []byte) (*YieldPeerInsufficientAmount, error) {
	args := c.ABI.Errors["YieldPeer__InsufficientAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldPeerInsufficientAmount{}, nil
}

// Error implements the error interface for YieldPeerInsufficientAmount.
func (e *YieldPeerInsufficientAmount) Error() string {
	return fmt.Sprintf("YieldPeerInsufficientAmount error:")
}

// DecodeYieldPeerNoZeroAmountError decodes a YieldPeer__NoZeroAmount error from revert data.
func (c *ParentPeer) DecodeYieldPeerNoZeroAmountError(data []byte) (*YieldPeerNoZeroAmount, error) {
	args := c.ABI.Errors["YieldPeer__NoZeroAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldPeerNoZeroAmount{}, nil
}

// Error implements the error interface for YieldPeerNoZeroAmount.
func (e *YieldPeerNoZeroAmount) Error() string {
	return fmt.Sprintf("YieldPeerNoZeroAmount error:")
}

// DecodeYieldPeerNotStrategyChainError decodes a YieldPeer__NotStrategyChain error from revert data.
func (c *ParentPeer) DecodeYieldPeerNotStrategyChainError(data []byte) (*YieldPeerNotStrategyChain, error) {
	args := c.ABI.Errors["YieldPeer__NotStrategyChain"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldPeerNotStrategyChain{}, nil
}

// Error implements the error interface for YieldPeerNotStrategyChain.
func (e *YieldPeerNotStrategyChain) Error() string {
	return fmt.Sprintf("YieldPeerNotStrategyChain error:")
}

// DecodeYieldPeerOnlyShareError decodes a YieldPeer__OnlyShare error from revert data.
func (c *ParentPeer) DecodeYieldPeerOnlyShareError(data []byte) (*YieldPeerOnlyShare, error) {
	args := c.ABI.Errors["YieldPeer__OnlyShare"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &YieldPeerOnlyShare{}, nil
}

// Error implements the error interface for YieldPeerOnlyShare.
func (e *YieldPeerOnlyShare) Error() string {
	return fmt.Sprintf("YieldPeerOnlyShare error:")
}

// DecodeYieldPeerPeerNotAllowedError decodes a YieldPeer__PeerNotAllowed error from revert data.
func (c *ParentPeer) DecodeYieldPeerPeerNotAllowedError(data []byte) (*YieldPeerPeerNotAllowed, error) {
	args := c.ABI.Errors["YieldPeer__PeerNotAllowed"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	peer, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for peer in YieldPeerPeerNotAllowed error")
	}

	return &YieldPeerPeerNotAllowed{
		Peer: peer,
	}, nil
}

// Error implements the error interface for YieldPeerPeerNotAllowed.
func (e *YieldPeerPeerNotAllowed) Error() string {
	return fmt.Sprintf("YieldPeerPeerNotAllowed error: peer=%v;", e.Peer)
}

func (c *ParentPeer) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	case common.Bytes2Hex(c.ABI.Errors["AccessControlBadConfirmation"].ID.Bytes()[:4]):
		return c.DecodeAccessControlBadConfirmationError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlEnforcedDefaultAdminDelay"].ID.Bytes()[:4]):
		return c.DecodeAccessControlEnforcedDefaultAdminDelayError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlEnforcedDefaultAdminRules"].ID.Bytes()[:4]):
		return c.DecodeAccessControlEnforcedDefaultAdminRulesError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlInvalidDefaultAdmin"].ID.Bytes()[:4]):
		return c.DecodeAccessControlInvalidDefaultAdminError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlUnauthorizedAccount"].ID.Bytes()[:4]):
		return c.DecodeAccessControlUnauthorizedAccountError(data)
	case common.Bytes2Hex(c.ABI.Errors["CCIPOperations__InvalidToken"].ID.Bytes()[:4]):
		return c.DecodeCCIPOperationsInvalidTokenError(data)
	case common.Bytes2Hex(c.ABI.Errors["CCIPOperations__InvalidTokenAmount"].ID.Bytes()[:4]):
		return c.DecodeCCIPOperationsInvalidTokenAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["CCIPOperations__NotEnoughLink"].ID.Bytes()[:4]):
		return c.DecodeCCIPOperationsNotEnoughLinkError(data)
	case common.Bytes2Hex(c.ABI.Errors["EnforcedPause"].ID.Bytes()[:4]):
		return c.DecodeEnforcedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["ExpectedPause"].ID.Bytes()[:4]):
		return c.DecodeExpectedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["InvalidRouter"].ID.Bytes()[:4]):
		return c.DecodeInvalidRouterError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentPeer__CurrentStrategyOptimal"].ID.Bytes()[:4]):
		return c.DecodeParentPeerCurrentStrategyOptimalError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentPeer__InactiveStrategyAdapter"].ID.Bytes()[:4]):
		return c.DecodeParentPeerInactiveStrategyAdapterError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentPeer__InitialActiveStrategyAlreadySet"].ID.Bytes()[:4]):
		return c.DecodeParentPeerInitialActiveStrategyAlreadySetError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentPeer__OnlyRebalancer"].ID.Bytes()[:4]):
		return c.DecodeParentPeerOnlyRebalancerError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentPeer__StrategyNotSupported"].ID.Bytes()[:4]):
		return c.DecodeParentPeerStrategyNotSupportedError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeCastOverflowedUintDowncast"].ID.Bytes()[:4]):
		return c.DecodeSafeCastOverflowedUintDowncastError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeERC20FailedOperation"].ID.Bytes()[:4]):
		return c.DecodeSafeERC20FailedOperationError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldFees__FeeRateTooHigh"].ID.Bytes()[:4]):
		return c.DecodeYieldFeesFeeRateTooHighError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldFees__NoFeesToWithdraw"].ID.Bytes()[:4]):
		return c.DecodeYieldFeesNoFeesToWithdrawError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__ChainNotAllowed"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerChainNotAllowedError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__InsufficientAmount"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerInsufficientAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__NoZeroAmount"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerNoZeroAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__NotStrategyChain"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerNotStrategyChainError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__OnlyShare"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerOnlyShareError(data)
	case common.Bytes2Hex(c.ABI.Errors["YieldPeer__PeerNotAllowed"].ID.Bytes()[:4]):
		return c.DecodeYieldPeerPeerNotAllowedError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}

// ActiveStrategyAdapterUpdatedTrigger wraps the raw log trigger and provides decoded ActiveStrategyAdapterUpdatedDecoded data
type ActiveStrategyAdapterUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into ActiveStrategyAdapterUpdated data
func (t *ActiveStrategyAdapterUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ActiveStrategyAdapterUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeActiveStrategyAdapterUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ActiveStrategyAdapterUpdated log: %w", err)
	}

	return &bindings.DecodedLog[ActiveStrategyAdapterUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerActiveStrategyAdapterUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ActiveStrategyAdapterUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ActiveStrategyAdapterUpdatedDecoded]], error) {
	event := c.ABI.Events["ActiveStrategyAdapterUpdated"]
	topics, err := c.Codec.EncodeActiveStrategyAdapterUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ActiveStrategyAdapterUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ActiveStrategyAdapterUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsActiveStrategyAdapterUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ActiveStrategyAdapterUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// AllowedChainSetTrigger wraps the raw log trigger and provides decoded AllowedChainSetDecoded data
type AllowedChainSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into AllowedChainSet data
func (t *AllowedChainSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[AllowedChainSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeAllowedChainSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode AllowedChainSet log: %w", err)
	}

	return &bindings.DecodedLog[AllowedChainSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerAllowedChainSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []AllowedChainSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[AllowedChainSetDecoded]], error) {
	event := c.ABI.Events["AllowedChainSet"]
	topics, err := c.Codec.EncodeAllowedChainSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for AllowedChainSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &AllowedChainSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsAllowedChainSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.AllowedChainSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// AllowedPeerSetTrigger wraps the raw log trigger and provides decoded AllowedPeerSetDecoded data
type AllowedPeerSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into AllowedPeerSet data
func (t *AllowedPeerSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[AllowedPeerSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeAllowedPeerSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode AllowedPeerSet log: %w", err)
	}

	return &bindings.DecodedLog[AllowedPeerSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerAllowedPeerSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []AllowedPeerSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[AllowedPeerSetDecoded]], error) {
	event := c.ABI.Events["AllowedPeerSet"]
	topics, err := c.Codec.EncodeAllowedPeerSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for AllowedPeerSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &AllowedPeerSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsAllowedPeerSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.AllowedPeerSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// CCIPGasLimitSetTrigger wraps the raw log trigger and provides decoded CCIPGasLimitSetDecoded data
type CCIPGasLimitSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into CCIPGasLimitSet data
func (t *CCIPGasLimitSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CCIPGasLimitSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCCIPGasLimitSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CCIPGasLimitSet log: %w", err)
	}

	return &bindings.DecodedLog[CCIPGasLimitSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerCCIPGasLimitSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CCIPGasLimitSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CCIPGasLimitSetDecoded]], error) {
	event := c.ABI.Events["CCIPGasLimitSet"]
	topics, err := c.Codec.EncodeCCIPGasLimitSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CCIPGasLimitSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CCIPGasLimitSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsCCIPGasLimitSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CCIPGasLimitSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// CCIPMessageReceivedTrigger wraps the raw log trigger and provides decoded CCIPMessageReceivedDecoded data
type CCIPMessageReceivedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into CCIPMessageReceived data
func (t *CCIPMessageReceivedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CCIPMessageReceivedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCCIPMessageReceived(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CCIPMessageReceived log: %w", err)
	}

	return &bindings.DecodedLog[CCIPMessageReceivedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerCCIPMessageReceivedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CCIPMessageReceivedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CCIPMessageReceivedDecoded]], error) {
	event := c.ABI.Events["CCIPMessageReceived"]
	topics, err := c.Codec.EncodeCCIPMessageReceivedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CCIPMessageReceived: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CCIPMessageReceivedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsCCIPMessageReceived(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CCIPMessageReceivedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// CCIPMessageSentTrigger wraps the raw log trigger and provides decoded CCIPMessageSentDecoded data
type CCIPMessageSentTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into CCIPMessageSent data
func (t *CCIPMessageSentTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CCIPMessageSentDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCCIPMessageSent(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CCIPMessageSent log: %w", err)
	}

	return &bindings.DecodedLog[CCIPMessageSentDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerCCIPMessageSentLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CCIPMessageSentTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CCIPMessageSentDecoded]], error) {
	event := c.ABI.Events["CCIPMessageSent"]
	topics, err := c.Codec.EncodeCCIPMessageSentTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CCIPMessageSent: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CCIPMessageSentTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsCCIPMessageSent(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CCIPMessageSentLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminDelayChangeCanceledTrigger wraps the raw log trigger and provides decoded DefaultAdminDelayChangeCanceledDecoded data
type DefaultAdminDelayChangeCanceledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminDelayChangeCanceled data
func (t *DefaultAdminDelayChangeCanceledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminDelayChangeCanceled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminDelayChangeCanceled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDefaultAdminDelayChangeCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminDelayChangeCanceled"]
	topics, err := c.Codec.EncodeDefaultAdminDelayChangeCanceledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminDelayChangeCanceled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminDelayChangeCanceledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDefaultAdminDelayChangeCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminDelayChangeCanceledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminDelayChangeScheduledTrigger wraps the raw log trigger and provides decoded DefaultAdminDelayChangeScheduledDecoded data
type DefaultAdminDelayChangeScheduledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminDelayChangeScheduled data
func (t *DefaultAdminDelayChangeScheduledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminDelayChangeScheduled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminDelayChangeScheduled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDefaultAdminDelayChangeScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminDelayChangeScheduled"]
	topics, err := c.Codec.EncodeDefaultAdminDelayChangeScheduledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminDelayChangeScheduled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminDelayChangeScheduledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDefaultAdminDelayChangeScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminDelayChangeScheduledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminTransferCanceledTrigger wraps the raw log trigger and provides decoded DefaultAdminTransferCanceledDecoded data
type DefaultAdminTransferCanceledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminTransferCanceled data
func (t *DefaultAdminTransferCanceledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminTransferCanceledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminTransferCanceled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminTransferCanceled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminTransferCanceledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDefaultAdminTransferCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferCanceledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminTransferCanceled"]
	topics, err := c.Codec.EncodeDefaultAdminTransferCanceledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminTransferCanceled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminTransferCanceledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDefaultAdminTransferCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminTransferCanceledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminTransferScheduledTrigger wraps the raw log trigger and provides decoded DefaultAdminTransferScheduledDecoded data
type DefaultAdminTransferScheduledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminTransferScheduled data
func (t *DefaultAdminTransferScheduledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminTransferScheduledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminTransferScheduled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminTransferScheduled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminTransferScheduledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDefaultAdminTransferScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferScheduledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminTransferScheduled"]
	topics, err := c.Codec.EncodeDefaultAdminTransferScheduledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminTransferScheduled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminTransferScheduledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDefaultAdminTransferScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminTransferScheduledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositForwardedToStrategyTrigger wraps the raw log trigger and provides decoded DepositForwardedToStrategyDecoded data
type DepositForwardedToStrategyTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DepositForwardedToStrategy data
func (t *DepositForwardedToStrategyTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositForwardedToStrategyDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositForwardedToStrategy(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositForwardedToStrategy log: %w", err)
	}

	return &bindings.DecodedLog[DepositForwardedToStrategyDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDepositForwardedToStrategyLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositForwardedToStrategyTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositForwardedToStrategyDecoded]], error) {
	event := c.ABI.Events["DepositForwardedToStrategy"]
	topics, err := c.Codec.EncodeDepositForwardedToStrategyTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositForwardedToStrategy: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositForwardedToStrategyTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDepositForwardedToStrategy(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositForwardedToStrategyLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositInitiatedTrigger wraps the raw log trigger and provides decoded DepositInitiatedDecoded data
type DepositInitiatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DepositInitiated data
func (t *DepositInitiatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositInitiatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositInitiated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositInitiated log: %w", err)
	}

	return &bindings.DecodedLog[DepositInitiatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDepositInitiatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositInitiatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositInitiatedDecoded]], error) {
	event := c.ABI.Events["DepositInitiated"]
	topics, err := c.Codec.EncodeDepositInitiatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositInitiated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositInitiatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDepositInitiated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositInitiatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositPingPongToChildTrigger wraps the raw log trigger and provides decoded DepositPingPongToChildDecoded data
type DepositPingPongToChildTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DepositPingPongToChild data
func (t *DepositPingPongToChildTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositPingPongToChildDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositPingPongToChild(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositPingPongToChild log: %w", err)
	}

	return &bindings.DecodedLog[DepositPingPongToChildDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDepositPingPongToChildLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositPingPongToChildTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositPingPongToChildDecoded]], error) {
	event := c.ABI.Events["DepositPingPongToChild"]
	topics, err := c.Codec.EncodeDepositPingPongToChildTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositPingPongToChild: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositPingPongToChildTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDepositPingPongToChild(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositPingPongToChildLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositToStrategyTrigger wraps the raw log trigger and provides decoded DepositToStrategyDecoded data
type DepositToStrategyTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into DepositToStrategy data
func (t *DepositToStrategyTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositToStrategyDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositToStrategy(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositToStrategy log: %w", err)
	}

	return &bindings.DecodedLog[DepositToStrategyDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerDepositToStrategyLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositToStrategyTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositToStrategyDecoded]], error) {
	event := c.ABI.Events["DepositToStrategy"]
	topics, err := c.Codec.EncodeDepositToStrategyTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositToStrategy: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositToStrategyTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsDepositToStrategy(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositToStrategyLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// FeeRateSetTrigger wraps the raw log trigger and provides decoded FeeRateSetDecoded data
type FeeRateSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into FeeRateSet data
func (t *FeeRateSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[FeeRateSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeFeeRateSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode FeeRateSet log: %w", err)
	}

	return &bindings.DecodedLog[FeeRateSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerFeeRateSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []FeeRateSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[FeeRateSetDecoded]], error) {
	event := c.ABI.Events["FeeRateSet"]
	topics, err := c.Codec.EncodeFeeRateSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for FeeRateSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &FeeRateSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsFeeRateSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.FeeRateSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// FeeTakenTrigger wraps the raw log trigger and provides decoded FeeTakenDecoded data
type FeeTakenTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into FeeTaken data
func (t *FeeTakenTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[FeeTakenDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeFeeTaken(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode FeeTaken log: %w", err)
	}

	return &bindings.DecodedLog[FeeTakenDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerFeeTakenLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []FeeTakenTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[FeeTakenDecoded]], error) {
	event := c.ABI.Events["FeeTaken"]
	topics, err := c.Codec.EncodeFeeTakenTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for FeeTaken: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &FeeTakenTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsFeeTaken(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.FeeTakenLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// FeesWithdrawnTrigger wraps the raw log trigger and provides decoded FeesWithdrawnDecoded data
type FeesWithdrawnTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into FeesWithdrawn data
func (t *FeesWithdrawnTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[FeesWithdrawnDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeFeesWithdrawn(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode FeesWithdrawn log: %w", err)
	}

	return &bindings.DecodedLog[FeesWithdrawnDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerFeesWithdrawnLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []FeesWithdrawnTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[FeesWithdrawnDecoded]], error) {
	event := c.ABI.Events["FeesWithdrawn"]
	topics, err := c.Codec.EncodeFeesWithdrawnTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for FeesWithdrawn: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &FeesWithdrawnTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsFeesWithdrawn(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.FeesWithdrawnLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PausedTrigger wraps the raw log trigger and provides decoded PausedDecoded data
type PausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into Paused data
func (t *PausedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PausedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePaused(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Paused log: %w", err)
	}

	return &bindings.DecodedLog[PausedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerPausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PausedDecoded]], error) {
	event := c.ABI.Events["Paused"]
	topics, err := c.Codec.EncodePausedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Paused: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PausedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsPaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PausedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalancerSetTrigger wraps the raw log trigger and provides decoded RebalancerSetDecoded data
type RebalancerSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into RebalancerSet data
func (t *RebalancerSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalancerSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalancerSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalancerSet log: %w", err)
	}

	return &bindings.DecodedLog[RebalancerSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerRebalancerSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalancerSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalancerSetDecoded]], error) {
	event := c.ABI.Events["RebalancerSet"]
	topics, err := c.Codec.EncodeRebalancerSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalancerSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalancerSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsRebalancerSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalancerSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleAdminChangedTrigger wraps the raw log trigger and provides decoded RoleAdminChangedDecoded data
type RoleAdminChangedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into RoleAdminChanged data
func (t *RoleAdminChangedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleAdminChangedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleAdminChanged(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleAdminChanged log: %w", err)
	}

	return &bindings.DecodedLog[RoleAdminChangedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerRoleAdminChangedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleAdminChangedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleAdminChangedDecoded]], error) {
	event := c.ABI.Events["RoleAdminChanged"]
	topics, err := c.Codec.EncodeRoleAdminChangedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleAdminChanged: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleAdminChangedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsRoleAdminChanged(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleAdminChangedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleGrantedTrigger wraps the raw log trigger and provides decoded RoleGrantedDecoded data
type RoleGrantedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into RoleGranted data
func (t *RoleGrantedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleGrantedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleGranted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleGranted log: %w", err)
	}

	return &bindings.DecodedLog[RoleGrantedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerRoleGrantedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleGrantedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleGrantedDecoded]], error) {
	event := c.ABI.Events["RoleGranted"]
	topics, err := c.Codec.EncodeRoleGrantedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleGranted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleGrantedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsRoleGranted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleGrantedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleRevokedTrigger wraps the raw log trigger and provides decoded RoleRevokedDecoded data
type RoleRevokedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into RoleRevoked data
func (t *RoleRevokedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleRevokedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleRevoked(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleRevoked log: %w", err)
	}

	return &bindings.DecodedLog[RoleRevokedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerRoleRevokedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleRevokedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleRevokedDecoded]], error) {
	event := c.ABI.Events["RoleRevoked"]
	topics, err := c.Codec.EncodeRoleRevokedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleRevoked: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleRevokedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsRoleRevoked(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleRevokedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ShareBurnUpdateTrigger wraps the raw log trigger and provides decoded ShareBurnUpdateDecoded data
type ShareBurnUpdateTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into ShareBurnUpdate data
func (t *ShareBurnUpdateTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ShareBurnUpdateDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeShareBurnUpdate(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ShareBurnUpdate log: %w", err)
	}

	return &bindings.DecodedLog[ShareBurnUpdateDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerShareBurnUpdateLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ShareBurnUpdateTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ShareBurnUpdateDecoded]], error) {
	event := c.ABI.Events["ShareBurnUpdate"]
	topics, err := c.Codec.EncodeShareBurnUpdateTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ShareBurnUpdate: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ShareBurnUpdateTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsShareBurnUpdate(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ShareBurnUpdateLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ShareMintUpdateTrigger wraps the raw log trigger and provides decoded ShareMintUpdateDecoded data
type ShareMintUpdateTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into ShareMintUpdate data
func (t *ShareMintUpdateTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ShareMintUpdateDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeShareMintUpdate(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ShareMintUpdate log: %w", err)
	}

	return &bindings.DecodedLog[ShareMintUpdateDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerShareMintUpdateLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ShareMintUpdateTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ShareMintUpdateDecoded]], error) {
	event := c.ABI.Events["ShareMintUpdate"]
	topics, err := c.Codec.EncodeShareMintUpdateTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ShareMintUpdate: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ShareMintUpdateTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsShareMintUpdate(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ShareMintUpdateLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// SharesBurnedTrigger wraps the raw log trigger and provides decoded SharesBurnedDecoded data
type SharesBurnedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into SharesBurned data
func (t *SharesBurnedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[SharesBurnedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeSharesBurned(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode SharesBurned log: %w", err)
	}

	return &bindings.DecodedLog[SharesBurnedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerSharesBurnedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []SharesBurnedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[SharesBurnedDecoded]], error) {
	event := c.ABI.Events["SharesBurned"]
	topics, err := c.Codec.EncodeSharesBurnedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for SharesBurned: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &SharesBurnedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsSharesBurned(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.SharesBurnedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// SharesMintedTrigger wraps the raw log trigger and provides decoded SharesMintedDecoded data
type SharesMintedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into SharesMinted data
func (t *SharesMintedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[SharesMintedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeSharesMinted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode SharesMinted log: %w", err)
	}

	return &bindings.DecodedLog[SharesMintedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerSharesMintedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []SharesMintedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[SharesMintedDecoded]], error) {
	event := c.ABI.Events["SharesMinted"]
	topics, err := c.Codec.EncodeSharesMintedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for SharesMinted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &SharesMintedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsSharesMinted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.SharesMintedLogHash()}},
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
	contract                        *ParentPeer // Keep reference for decoding
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

func (c *ParentPeer) LogTriggerStrategyRegistrySetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []StrategyRegistrySetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[StrategyRegistrySetDecoded]], error) {
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

func (c *ParentPeer) FilterLogsStrategyRegistrySet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// StrategyUpdatedTrigger wraps the raw log trigger and provides decoded StrategyUpdatedDecoded data
type StrategyUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into StrategyUpdated data
func (t *StrategyUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[StrategyUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeStrategyUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode StrategyUpdated log: %w", err)
	}

	return &bindings.DecodedLog[StrategyUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerStrategyUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []StrategyUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[StrategyUpdatedDecoded]], error) {
	event := c.ABI.Events["StrategyUpdated"]
	topics, err := c.Codec.EncodeStrategyUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for StrategyUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &StrategyUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsStrategyUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.StrategyUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// SupportedProtocolSetTrigger wraps the raw log trigger and provides decoded SupportedProtocolSetDecoded data
type SupportedProtocolSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into SupportedProtocolSet data
func (t *SupportedProtocolSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[SupportedProtocolSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeSupportedProtocolSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode SupportedProtocolSet log: %w", err)
	}

	return &bindings.DecodedLog[SupportedProtocolSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerSupportedProtocolSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []SupportedProtocolSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[SupportedProtocolSetDecoded]], error) {
	event := c.ABI.Events["SupportedProtocolSet"]
	topics, err := c.Codec.EncodeSupportedProtocolSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for SupportedProtocolSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &SupportedProtocolSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsSupportedProtocolSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.SupportedProtocolSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// UnpausedTrigger wraps the raw log trigger and provides decoded UnpausedDecoded data
type UnpausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into Unpaused data
func (t *UnpausedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[UnpausedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeUnpaused(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Unpaused log: %w", err)
	}

	return &bindings.DecodedLog[UnpausedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerUnpausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []UnpausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[UnpausedDecoded]], error) {
	event := c.ABI.Events["Unpaused"]
	topics, err := c.Codec.EncodeUnpausedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Unpaused: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &UnpausedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsUnpaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.UnpausedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawCompletedTrigger wraps the raw log trigger and provides decoded WithdrawCompletedDecoded data
type WithdrawCompletedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawCompleted data
func (t *WithdrawCompletedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawCompletedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawCompleted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawCompleted log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawCompletedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerWithdrawCompletedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawCompletedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawCompletedDecoded]], error) {
	event := c.ABI.Events["WithdrawCompleted"]
	topics, err := c.Codec.EncodeWithdrawCompletedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawCompleted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawCompletedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsWithdrawCompleted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawCompletedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawForwardedToStrategyTrigger wraps the raw log trigger and provides decoded WithdrawForwardedToStrategyDecoded data
type WithdrawForwardedToStrategyTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawForwardedToStrategy data
func (t *WithdrawForwardedToStrategyTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawForwardedToStrategyDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawForwardedToStrategy(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawForwardedToStrategy log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawForwardedToStrategyDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerWithdrawForwardedToStrategyLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawForwardedToStrategyTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawForwardedToStrategyDecoded]], error) {
	event := c.ABI.Events["WithdrawForwardedToStrategy"]
	topics, err := c.Codec.EncodeWithdrawForwardedToStrategyTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawForwardedToStrategy: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawForwardedToStrategyTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsWithdrawForwardedToStrategy(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawForwardedToStrategyLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawFromStrategyTrigger wraps the raw log trigger and provides decoded WithdrawFromStrategyDecoded data
type WithdrawFromStrategyTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawFromStrategy data
func (t *WithdrawFromStrategyTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawFromStrategyDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawFromStrategy(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawFromStrategy log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawFromStrategyDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerWithdrawFromStrategyLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFromStrategyTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFromStrategyDecoded]], error) {
	event := c.ABI.Events["WithdrawFromStrategy"]
	topics, err := c.Codec.EncodeWithdrawFromStrategyTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawFromStrategy: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawFromStrategyTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsWithdrawFromStrategy(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawFromStrategyLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawInitiatedTrigger wraps the raw log trigger and provides decoded WithdrawInitiatedDecoded data
type WithdrawInitiatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawInitiated data
func (t *WithdrawInitiatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawInitiatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawInitiated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawInitiated log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawInitiatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerWithdrawInitiatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawInitiatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawInitiatedDecoded]], error) {
	event := c.ABI.Events["WithdrawInitiated"]
	topics, err := c.Codec.EncodeWithdrawInitiatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawInitiated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawInitiatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsWithdrawInitiated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawInitiatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawPingPongToChildTrigger wraps the raw log trigger and provides decoded WithdrawPingPongToChildDecoded data
type WithdrawPingPongToChildTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ParentPeer // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawPingPongToChild data
func (t *WithdrawPingPongToChildTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawPingPongToChildDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawPingPongToChild(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawPingPongToChild log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawPingPongToChildDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentPeer) LogTriggerWithdrawPingPongToChildLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawPingPongToChildTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawPingPongToChildDecoded]], error) {
	event := c.ABI.Events["WithdrawPingPongToChild"]
	topics, err := c.Codec.EncodeWithdrawPingPongToChildTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawPingPongToChild: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawPingPongToChildTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentPeer) FilterLogsWithdrawPingPongToChild(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawPingPongToChildLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}
