import * as dotenv from "dotenv";

import { parseEther } from "ethers/lib/utils";
import { HardhatUserConfig, task } from "hardhat/config";
import { HardhatNetworkAccountsUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import {accountsTask} from "./tasks/accounts";

// Load environment variables from .env
dotenv.config();

// Load hardhat tasks
accountsTask();

const FORK_FUJI = false
const FORK_MAINNET = false
const forkingData = FORK_FUJI ? {
  enabled: FORK_FUJI,
  url: 'https://api.avax-test.network/ext/bc/C/rpc',
} : FORK_MAINNET ? {
  enabled: FORK_MAINNET,
  url: 'https://api.avax.network/ext/bc/C/rpc',
  // blockNumber: 12590000
} : undefined

const accountsEnv: string[] = [
  process.env.PRIVATE_KEY_2 !== undefined ? process.env.PRIVATE_KEY_2: "",
  process.env.PRIVATE_KEY_1 !== undefined ? process.env.PRIVATE_KEY_1: ""
];

const accountsFork: HardhatNetworkAccountsUserConfig = [{
  privateKey: process.env.PRIVATE_KEY_2 !== undefined ? process.env.PRIVATE_KEY_2: "",
  balance: parseEther('1000').toString(),
}];

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      gasPrice: 225000000000,
      chainId: 43114,
      forking: forkingData,
      accounts: FORK_FUJI ? accountsFork : undefined
      // allowUnlimitedContractSize: true
    },
    local: {
      url: 'http://localhost:8545/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      timeout: 100000,
      // allowUnlimitedContractSize: true
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: accountsEnv,
    },
    mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      // accounts: process.env.PRIVATE_KEY_2 !== undefined ? [process.env.PRIVATE_KEY_2] : [],
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
