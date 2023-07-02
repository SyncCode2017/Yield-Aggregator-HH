
// require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-etherscan");
// require("dotenv").config();
// require("hardhat-deploy");
require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

const fs = require("fs");
/** @type import('hardhat/config').HardhatUserConfig */

const PRIVATE_KEY =
  process.env.PRIVATE_KEY ||
  "0000000000000000000000000000000000000000000000000000000000000000";
const PRIVATE_KEY_2 =
  process.env.PRIVATE_KEY_Hardhat_0 ||
  "0000000000000000000000000000000000000000000000000000000000000000";
const PRIVATE_KEY_3 =
  process.env.PRIVATE_KEY_Hardhat_1 ||
  "0000000000000000000000000000000000000000000000000000000000000000";
const POLYGON_MUMBAI_KEY =
  process.env.POLYGONSCAN_API_KEY ||
  "0000000000000000000000000000000000000000000000000000000000000000";

// require("./tasks");
require("./tasks/service-tasks");

let blockNumberToPin;
try {
  const blockOffset = 20; // Keep above 10 (largest chain re-org was 7 block deeps), while also keeping to a relatively small value to get the 'safest' recent block
  blockNumberToPin = JSON.parse(
    fs.readFileSync("./utils/config.json").toString()
  ).blockNumber;
  blockNumberToPin -= blockOffset; // subtract block number by blockOffset to remove the risk of uncle blocks and increase Alchemy performance
} catch (err) {
  console.error(err);
  console.log(
    "There was an error parsing blockNumber from JSON file. Try running `hh updateBlockNumber` separately from your terminal before running hh test"
  );
}

module.exports = {
  defaultNetwork: "hardhat",

  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.4.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      // polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGON_MUMBAI_KEY,
      // goerli: ETHERSCAN_API_KEY,
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    // outputFile: "gas-report.txt",
    noColors: true,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_KEY}`, // Fork live Ethereum mainnet when testing locally
        blockNumber: blockNumberToPin, // We pin to a block so we don't keep requesting Alchemy for the chain's new state so tests run faster. Update this frequently
      },
    },
    localhost: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_KEY}`, // As above
        blockNumber: blockNumberToPin, // As above
      },
    },

    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
      saveDeployments: true,
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_MUMBAI_KEY}`,
      chainId: 80001,
      accounts: [`${PRIVATE_KEY}`],
      saveDeployments: true,
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
      saveDeployments: true,
    },
    // hardhat: {
    //   chainId: 31337,
    // },
  },
  namedAccounts: {
    deployer: {
      default: 0,
      1: 0,
    },
    Alice: {
      default: 1,
      1: 1,
    },
  },
  mocha: {
    timeout: 100000000,
  },
};