if (!secrets.api) {
  throw Error('Proxy API URL not provided');
}

const chainSelectorMap = {
  Avalanche: '14767482510784806043', // Fuji
  Ethereum: '16015286601757825753', // Sepolia
  Base: '10344971235874465080', // Sepolia
};
const allowedChains = Object.keys(chainSelectorMap);

try {
  const response = await Functions.makeHttpRequest({
    url: secrets.api,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
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
    return Functions.encodeString(JSON.stringify(response));
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
    const protocolId = new Uint8Array(32); // Zero bytes for invalid case
    const result = new Uint8Array(64);
    result.set(selectorBytes, 0);
    result.set(protocolId, 32);
    return result;
  }

  const chainSelector = chainSelectorMap[pool.chain] || '0';
  const selectorBytes = Functions.encodeUint256(BigInt(chainSelector));

  let protocolId;
  try {
    const ethers = await import('npm:ethers@5.7.2');
    const projectBytes = ethers.utils.toUtf8Bytes(pool.project); // Convert string to UTF-8 bytes
    const protocolIdBytes = ethers.utils.arrayify(
      ethers.utils.keccak256(projectBytes)
    ); // Hash to bytes32
    protocolId = new Uint8Array(32);
    protocolId.set(protocolIdBytes, 0);
  } catch (e) {
    console.log('Ethers import failed:', e.message);
  }

  const result = new Uint8Array(64);
  result.set(selectorBytes, 0);
  result.set(protocolId, 32);
  return result;
} catch (error) {
  console.log('General Error:', error.message);
  return Functions.encodeString(error.message);
}

// @review - this would need to be minimized into an updated src.min.js before deployment
