require('babel-register');
require('babel-polyfill');


var HDWalletProvider = require("@truffle/hdwallet-provider");  // 导入模块
var mnemonic = "position apart sketch elder mountain end guitar feel cliff alert slush duck";  //MetaMask的助记词。

module.exports = {
  networks: {
    goerli: {
        provider: function() {
            // mnemonic表示MetaMask的助记词。 
            return new HDWalletProvider(mnemonic, "https://goerli.infura.io/v3/7d699ab372214c0fb640e4f35ce73d9e");   
        },
        network_id: "*",  // match any network
        gas: 30123880,
        gasPrice: 20000000000,
        confirmations: 2,    // # of confs to wait between deployments. (default: 0)
        timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
        skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    development: {
      host: "10.8.13.98",
      port: 8545,
      network_id: "*",
      //gas: 3000000,
      //gasPrice: 250000000700,
    },
  },  
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "0.7.6",
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: "byzantium"
    }
  }
}
