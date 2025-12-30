package strategy

import "math/big"

func CalculateAaveAPY(apr *big.Int) *big.Int {
	apy := (1 + apr / SecondsPerYear) ^ SecondsPerYear − 1
	return apy
}