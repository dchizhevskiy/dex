import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ExchangeV2, IERC20, IFactory } from "../typechain-types";

describe("ExchangeV2", () => {
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let token: IERC20;
  let factory: IFactory;
  let exchange: ExchangeV2;

  beforeEach(async () => {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock ERC20 token
    const Token = await ethers.getContractFactory("ERC20Mock");
    token = await Token.deploy(ethers.parseEther("1000000"));
    token.waitForDeployment();
    token.transfer(user1, ethers.parseEther("10000"))
    token.transfer(user2, ethers.parseEther("10000"))

    // Deploy the factory contract
    const Factory = await ethers.getContractFactory("Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();
    //await factory.deployed();
    const tokenAddress = await token.getAddress()
    const tx = await factory.createExchange(tokenAddress);
 
    await tx.wait();

    const exchangeAddress = await factory.getExchange(tokenAddress)
    exchange =  await ethers.getContractAt('ExchangeV2', exchangeAddress)
  });

  describe("Deployment", () => {
    it("Should set the correct token address", async () => {
      expect(await exchange.tokenAddress()).to.equal(await token.getAddress());
    });

    it("Should set the correct factory address", async () => {
      expect(await exchange.factoryAddress()).to.equal(await factory.getAddress());
    });
  });

  describe("addLiquidity", () => {
    it("Should add liquidity for the first time", async () => {
      const ethAmount = ethers.parseEther("1");
      const tokenAmount = ethers.parseEther("100");
      const exchangeAddress = await exchange.getAddress();
      // Approve tokens for the exchange
      await token.connect(user1).approve(exchangeAddress, tokenAmount);

      // Add liquidity
      expect(await exchange.connect(user1).addLiquidity(0, tokenAmount, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount }))
        .to.emit(exchange, "AddLiquidity")
        .withArgs(user1.address, ethAmount, tokenAmount);

      // Check balances
      expect(await exchange.balanceOf(user1.address)).to.equal(ethAmount);
      expect(await token.balanceOf(exchangeAddress)).to.equal(tokenAmount);
    });

    it("Should add liquidity after initial liquidity", async () => {
      const ethAmount1 = ethers.parseEther("1");
      const tokenAmount1 = ethers.parseEther("100");

      // Add initial liquidity
      await token.connect(user1).approve(await exchange.getAddress(), tokenAmount1);
      await exchange.connect(user1).addLiquidity(ethAmount1, tokenAmount1, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount1 });

      const ethAmount2 = ethers.parseEther("1");
      const tokenAmount2 = ethers.parseEther("110");

      // Add second liquidity
      await token.connect(user2).approve(exchange.getAddress(), tokenAmount2);
      expect(await exchange.connect(user2).addLiquidity(10, tokenAmount2, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount2 }))
        .to.emit(exchange, "AddLiquidity")
        .withArgs(user2.address, ethAmount2, tokenAmount2);

      // Check balances
      expect(await exchange.balanceOf(user2.address)).to.be.closeTo(ethAmount2, ethers.parseEther("0.001"));
    });
  });

  describe("removeLiquidity", () => {
    it("Should remove liquidity", async () => {
      const ethAmount = ethers.parseEther("1");
      const tokenAmount = ethers.parseEther("100");

      // Add liquidity
      await token.connect(user1).approve(await exchange.getAddress(), tokenAmount);
      await exchange.connect(user1).addLiquidity(0, tokenAmount, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount });

      // Remove liquidity
      const liquidity = await exchange.balanceOf(user1.address);
      expect(await token.balanceOf(user1.address)).to.equal(ethers.parseEther("10000")-tokenAmount);
      await expect(
        exchange.connect(user1).removeLiquidity(liquidity, ethAmount, tokenAmount, Math.floor(Date.now() / 1000) + 1000))
        .to.emit(exchange, "RemoveLiquidity")
        .withArgs(user1.address, ethAmount, tokenAmount);

      // Check balances
      expect(await exchange.balanceOf(user1.address)).to.equal(0);
      const balance = await token.balanceOf(user1.address)
      expect(await token.balanceOf(user1.address)).to.equal(10000000000000000000000n);
    });
  });

  describe("ethToTokenSwapInput", () => {
    it("Should swap ETH for tokens", async () => {
      const ethAmount = ethers.parseEther("1");
      const tokenAmount = ethers.parseEther("100");

      const tokenMinToSwap = ethers.parseEther("0.1");

      // Add liquidity
      await token.connect(user1).approve(await exchange.getAddress(), tokenAmount);
      await exchange.connect(user1).addLiquidity(0, tokenAmount, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount });

      const user2Balance = await token.balanceOf(user2.address);
      // Swap ETH for tokens
      const swapAmount = ethers.parseEther("0.1");
      expect(await exchange.connect(user2).ethToTokenSwapInput(tokenMinToSwap, Math.floor(Date.now() / 1000) + 1000, { value: swapAmount }))
        .to.emit(exchange, "TokenPurchase")
        .withArgs(user2.address, swapAmount, BigInt("9090909090909090909"));
      // Check balances
      expect(await token.balanceOf(user2.address)).to.equal(user2Balance+ BigInt("9090909090909090909"));
    });
  });

  describe("tokenToEthSwapInput", () => {
    it("Should swap tokens for ETH", async () => {
      const ethAmount = ethers.parseEther("1");
      const tokenAmount = ethers.parseEther("100");
      const minEthAmount = ethers.parseEther("0.08");
      // Add liquidity
      await token.connect(user1).approve(await exchange.getAddress(), tokenAmount);
      await exchange.connect(user1).addLiquidity(0, tokenAmount, Math.floor(Date.now() / 1000) + 1000, { value: ethAmount });
      // Swap tokens for ETH
      const swapAmount = ethers.parseEther("100");
      await token.connect(user2).approve(exchange.getAddress(), swapAmount);
      await expect(
        exchange.connect(user2).tokenToEthSwapInput(swapAmount, minEthAmount, Math.floor(Date.now() / 1000) + 1000))
        .to.emit(exchange, "EthPurchase")
        .withArgs(user2.address, swapAmount, BigInt("500000000000000000"));
     // Check balances
      expect(await ethers.provider.getBalance(await exchange.getAddress())).to.be.closeTo(ethers.parseEther("0.5"), ethers.parseEther("0.01"));
    });
  });
});