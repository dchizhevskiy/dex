// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IExchange {
    function addLiquidity(uint256 minLiquidity, uint256 maxTokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 minEth, uint256 minTokens, uint256 deadline) external returns (uint256, uint256);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable returns (uint256);
    
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline) external returns (uint256);
    
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256);
    
    function tokenAddress() external view returns (address);
    function factoryAddress() external view returns (address);

    // ERC20 Functions
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
}
