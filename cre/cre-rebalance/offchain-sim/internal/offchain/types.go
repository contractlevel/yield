package offchain

// Strategy pool fetched from DefiLlama
type Pool struct {
	Chain   string  `json:"chain"`
	Project string  `json:"project"`
	Symbol  string  `json:"symbol"`
	Apy     float64 `json:"apy"`
}

// DefiLlama API response structure
type APIResponse struct {
	Data []Pool `json:"data"`
}

// Types used in workflow configuration - should be deleted after moved to real workflow internal
type Config struct {
	Schedule string `json:"schedule"`
}

type Strategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}
