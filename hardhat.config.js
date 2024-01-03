
require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

const GOERLI_PRIVATE_KEY = process.env.TOP_HAT_PRIVATE_KEY;

module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
      },
    },
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
      accounts: [`0x${GOERLI_PRIVATE_KEY}`]
    },
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};

