require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-dependency-compiler');
require('hardhat-contract-sizer');
require("@nomicfoundation/hardhat-verify");
const {toNumber} = require("ethers");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          evmVersion: 'paris',
          optimizer: {
            enabled: true,
            runs: 999999
          }
        }
      }
    ]
  },
  networks: {
    btclayer2: {
      url: `${process.env.NETWORK_URL}`,
      timeout: 2000000,
      accounts: [`${process.env.PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: {
      btclayer2: "no-api-key-needed"
    },
    // apiKey: "process.env.API_KEY",
    customChains: [
      {
        network: "btclayer2",
        chainId: toNumber(`${process.env.CHAIN_ID}`),
        urls: {
          apiURL: `${process.env.EXPLORER_API_URL}`,
          browserURL: `${process.env.EXPLORER_URL}`
        }
      }
    ]
  }
};
