// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";


const ExchangeModule = buildModule("ExchangeModule", (m) => {

  const erc20Mock = m.contract("ERC20Mock", [ethers.parseEther("100")]);
  const factory = m.contract("Factory", []);

  const exchange = m.call(factory, "createExchange", [erc20Mock]);

  return { factory };
});

export default ExchangeModule;
