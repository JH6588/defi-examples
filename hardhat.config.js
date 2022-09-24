const secrets = require("./secret.json");

require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.9",
  etherscan: {
    apiKey: secrets.ETH_API_KEY
  },
  networks : {
    hardhat:{
      forking :{
        url: "https://eth-mainnet.g.alchemy.com/v2/613t3mfjTevdrCwDl28CVvuk6wSIxRPi"

            }
         },
      goerli : {
        url: `https://eth-goerli.alchemyapi.io/v2/${secrets.ALCHEMY_API_KEY}`,
        accounts: [secrets.PRIVATE_KEY]

  }
  
  }
};
