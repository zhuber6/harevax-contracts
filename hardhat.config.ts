import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const FORK_FUJI = false
const FORK_MAINNET = true
const forkingData = FORK_FUJI ? {
  url: 'https://api.avax-test.network/ext/bc/C/rpc',
} : FORK_MAINNET ? {
  url: 'https://api.avax.network/ext/bc/C/rpc',
  // blockNumber: 12590000
} : undefined

const config: HardhatUserConfig = {
  solidity: "0.8.13",
  networks: {
    hardhat: {
      gasPrice: 225000000000,
      chainId: 43114,
      forking: forkingData
    },
    local: {
      url: 'http://localhost:8545/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      timeout: 100000
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43113,
      // accounts: [process.env.PRIVATE_KEY_2]
    },
    mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      // accounts: [process.env.PRIVATE_KEY]
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./src",
    tests: "./hh-test",
    cache: "./hh-cache",
    artifacts: "./artifacts"
  },
};

export default config;
