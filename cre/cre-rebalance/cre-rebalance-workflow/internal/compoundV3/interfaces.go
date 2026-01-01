package compoundV3

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type CometInterface interface {
	TotalSupply(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
	TotalBorrow(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
	// input: uint256 utilization = totalBorrow / totalSupply
	GetSupplyRate(runtime cre.Runtime, input comet.GetSupplyRateInput, blockNumber *big.Int) cre.Promise[*big.Int]
	GetUtilization(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
}