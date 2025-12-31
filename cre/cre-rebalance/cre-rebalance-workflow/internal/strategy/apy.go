package strategy

import (
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
)

func CalculateAaveV3APY(apr *big.Rat) *big.Int {
	apy := (1 + apr / SecondsPerYear) ^ SecondsPerYear − 1
	return apy
}

func CalculateAPY(strategy onchain.Strategy) *big.Int {

}