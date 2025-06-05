const axios = require('axios');

exports.handler = async (event) => {
  try {
    console.log('Raw Event:', JSON.stringify(event, null, 2));

    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Request body is missing' }),
      };
    }

    let body;
    try {
      body = JSON.parse(event.body);
    } catch (e) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: `Invalid JSON: ${e.message}` }),
      };
    }

    console.log('Parsed Body:', JSON.stringify(body, null, 2));

    const { symbol, projects, chains } = body;
    if (!symbol || !projects || !chains) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required parameters' }),
      };
    }

    const { data } = await axios.get('https://yields.llama.fi/pools');
    if (!data.data || !Array.isArray(data.data)) {
      throw new Error('Invalid DeFiLlama response');
    }

    const pools = data.data.filter(
      (pool) =>
        pool.symbol?.toUpperCase().includes(symbol.toUpperCase()) &&
        pool.stablecoin &&
        projects.includes(pool.project) &&
        chains.includes(pool.chain)
    );

    const highestApyPool = pools.reduce(
      (max, pool) => ((pool.apy || 0) > (max.apy || 0) ? pool : max),
      pools[0] || null
    );

    return {
      statusCode: 200,
      body: JSON.stringify(
        highestApyPool
          ? {
              chain: highestApyPool.chain,
              project: highestApyPool.project,
              apy: highestApyPool.apy,
            }
          : {}
      ),
    };
  } catch (error) {
    console.error('Error:', error.message);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
