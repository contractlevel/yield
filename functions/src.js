async function main() {
  if (!secrets.api) {
    throw Error('Proxy API URL not provided');
  }

  const chainSelectorMap = {
    Arbitrum: '4949039107694359620',
    Ethereum: '5009297550715157269',
    Base: '15971525489660198786',
    Optimism: '3734403246176062136',
  };
  const allowedChains = Object.keys(chainSelectorMap);

  try {
    const response = await Functions.makeHttpRequest({
      url: secrets.api,
      method: 'POST',
      data: {
        symbol: 'USDC',
        projects: ['aave-v3', 'compound-v3'],
        chains: allowedChains,
      },
      timeout: 9000,
    });

    console.log(
      'Proxy API Response:',
      JSON.stringify(
        {
          status: response.status,
          error: response.error,
          message: response.message,
          data: response.data ? response.data : 'No data',
        },
        null,
        2
      )
    );

    if (response.error || !response.data || !response.data.chain) {
      console.log('Error or Invalid Data:', response.error || 'No valid pool');
      const selectorBytes = Functions.encodeUint256(BigInt(0));
      const enumBytes = Functions.encodeUint256(0);
      const result = new Uint8Array(64);
      result.set(selectorBytes, 0);
      result.set(enumBytes, 32);
      return result;
    }

    console.log(
      'Received Pool:',
      response.data.chain,
      response.data.project,
      response.data.apy
    );

    const pool = response.data;
    if (
      !allowedChains.includes(pool.chain) ||
      !['aave-v3', 'compound-v3'].includes(pool.project)
    ) {
      console.log('Invalid Pool Data:', pool);
      const selectorBytes = Functions.encodeUint256(BigInt(0));
      const enumBytes = Functions.encodeUint256(0);
      const result = new Uint8Array(64);
      result.set(selectorBytes, 0);
      result.set(enumBytes, 32);
      return result;
    }

    const protocolEnum = pool.project === 'aave-v3' ? 0 : 1;
    const chainSelector = chainSelectorMap[pool.chain] || '0';

    const selectorBytes = Functions.encodeUint256(BigInt(chainSelector));
    const enumBytes = Functions.encodeUint256(protocolEnum);
    const result = new Uint8Array(64);
    result.set(selectorBytes, 0);
    result.set(enumBytes, 32);
    return result;
  } catch (error) {
    console.log('General Error:', error.message);
    const selectorBytes = Functions.encodeUint256(BigInt(0));
    const enumBytes = Functions.encodeUint256(0);
    const result = new Uint8Array(64);
    result.set(selectorBytes, 0);
    result.set(enumBytes, 32);
    return result;
  }
}

return main();
