package aaveV3

// Dependency injection for AaveV3.
var (
	newPoolAddressesProviderBindingFunc = newPoolAddressesProviderBinding
	getProtocolDataProviderBindingFunc  = getProtocolDataProviderBinding
	getStrategyBindingFunc              = getStrategyBinding
	getCalculateInterestRatesParamsFunc = getCalculateInterestRatesParams
	calculateAPYFromContractFunc        = calculateAPYFromContract
)