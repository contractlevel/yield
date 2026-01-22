package compoundV3

import (
	"fmt"

	"rebalance/contracts/evm/src/generated/comet"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func newCometBinding(client *evm.Client, addr string) (CometInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid Comet address: %s", addr)
	}
	cometAddr := common.HexToAddress(addr)

	return comet.NewComet(client, cometAddr, nil)
}