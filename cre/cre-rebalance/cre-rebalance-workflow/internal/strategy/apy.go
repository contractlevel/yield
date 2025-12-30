package strategy

import "math/big"

func CalculateAPY(apr *big.Int) (*big.Int, error) {
	apy := (1 + apr / SecondsPerYear) ^ SecondsPerYear − 1
	return apy, nil
}