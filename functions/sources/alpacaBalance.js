
if (
  secrets.alpacaKey == "" ||
  secrets.alpacaSecret === ""
) {
  throw Error(
    "need alpaca keys"
  )
}

// To make an HTTP request, use the Functions.makeHttpRequest function
// Functions.makeHttpRequest function parameters:
// - url
// - method (optional, defaults to 'GET')
// - headers: headers supplied as an object (optional)
// - params: URL query parameters supplied as an object (optional)
// - data: request body supplied as an object (optional)
// - timeout: maximum request duration in ms (optional, defaults to 10000ms)
// - responseType: expected response type (optional, defaults to 'json')

// Use multiple APIs & aggregate the results to enhance decentralization
// const coinMarketCapRequest = Functions.makeHttpRequest({
//   url: `https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?convert=USD&id=${coinMarketCapCoinId}`,
//   // Get a free API key from https://coinmarketcap.com/api/
//   headers: { "X-CMC_PRO_API_KEY": secrets.apiKey },
// })
// const coinGeckoRequest = Functions.makeHttpRequest({
//   url: `https://api.coingecko.com/api/v3/simple/price?ids=${coinGeckoCoinId}&vs_currencies=usd`,
// })
// const coinPaprikaRequest = Functions.makeHttpRequest({
//   url: `https://api.coinpaprika.com/v1/tickers/${coinPaprikaCoinId}`,
// })
// // This dummy request simulates a failed API request
// const badApiRequest = Functions.makeHttpRequest({
//   url: `https://badapi.com/price/symbol/${badApiCoinId}`,
// })


