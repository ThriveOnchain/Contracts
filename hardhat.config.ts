import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

// const providerApiKey = process.env.ALCHEMY_API_KEY;
const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
const basescanApiKey = process.env.BASESCAN_API_KEY;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      outputSelection: {
        "*": {
          "*": [
            "abi",
            "evm.bytecode",
            "evm.deployedBytecode",
            "metadata", // <-- add this
          ],
        },
      },
    },
  },
  defaultNetwork: "baseSepolia",
  // defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: {
      default: "0xE3c347cEa95B7BfdB921074bdb39b8571F905f6D",
    },
    wallet5: {
      default: "0xE3c347cEa95B7BfdB921074bdb39b8571F905f6D",
    },
  },
  networks: {
    base: {
      url: "https://mainnet.base.org",
      accounts: [deployerPrivateKey!],
      verify: {
        etherscan: {
          apiUrl: "https://api.basescan.org/api",
          apiKey: basescanApiKey,
        },
      },
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      accounts: [deployerPrivateKey!],
      verify: {
        etherscan: {
          apiUrl: "https://api-sepolia.basescan.org",
          apiKey: basescanApiKey,
        },
      },
    },
  },
  verify: {
    etherscan: {
      apiKey: `${etherscanApiKey}`,
    },
  },
};

export default config;
