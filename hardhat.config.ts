import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/Y4vxWJN9CXq-Na_jVaUzR8aG8nsGKUTh",
      accounts: ["e2464b06d0848c75f5cb55f1ba95489a2efe8d3a032f261638f74b794f8b3347"]
    }
  },
  etherscan: {
    apiKey: {
      sepolia: "D27JDV4IPDMKBVG1TI75ZII6D23UD24HNA",
    },
  },
};

export default config;
