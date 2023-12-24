require("@nomiclabs/hardhat-waffle");


module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
      },
      // loggingEnabled: true 
    },
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
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
