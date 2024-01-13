require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-dependency-compiler');
require('hardhat-contract-sizer');
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
    },
  }
};
