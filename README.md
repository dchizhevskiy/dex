# DEX Project

This project is simple DEX smart contracts project.
## Entity Relationship Diagram 
![Diagram](https://github.com/dchizhevskiy/dex/blob/master/schema.png)

## Sepolia Deployed contracts
   * [Factory Contract](https://sepolia.etherscan.io/address/0x6aadec1817cbe114707878b17861adf449a2793d).
   * [Exchange Contract](https://sepolia.etherscan.io/address/0x1ff369B288358Abaa0323E385Dfb560A3D29601F).
   * [ERC20Mock Contract](https://sepolia.etherscan.io/address/0x1acd9d14f7b9131e88a98823336d80c945583e63).
   * [Deployer](https://sepolia.etherscan.io/address/0xd104b6D6Fc2838cFB121df05c2b4cC7Ce5c412c5).

 ### Deployment on the sepolia was done in 2 steps. 
   * Deployment of the contract
        npx hardhat ignition deploy ignition/modules/Exchange.ts --network sepolia --verify
   * Verification of the Exchange as it was created by the Factory as inner call
        npx hardhat verify --network sepolia 0x1ff369B288358Abaa0323E385Dfb560A3D29601F "0x1ACD9d14F7b9131e88a98823336D80c945583E63"

## Local run
   * Install libraries :      npm i 
   * Compile smart contracts: npx hardhat compile
   * Run local tests:         npx hardhat test