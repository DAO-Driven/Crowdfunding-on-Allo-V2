require("@nomiclabs/hardhat-waffle");


module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
      },
    },
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/k6px3XV2CMs2pZjXklvjGc8A0i-SujVf",
    },
  },
  solidity: "0.8.20",
};
