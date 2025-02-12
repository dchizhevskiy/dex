// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IExchange.sol';
import './interfaces/IFactory.sol';

contract ExchangeV2 is IExchange {
    string public constant name = "Exchange";
    string public constant symbol = "EXCH";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    address public token;
    IFactory public factory;

    event TokenPurchase(address indexed buyer, uint256 indexed ethSold, uint256 indexed tokensBought);
    event EthPurchase(address indexed buyer, uint256 indexed tokensSold, uint256 indexed ethBought);
    event AddLiquidity(address indexed provider, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event RemoveLiquidity(address indexed provider, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
   
    constructor(address tokenAddr) {
        require(tokenAddr != address(0), "Invalid token address");
        factory = IFactory(msg.sender);
        token = tokenAddr;
    }

    function addLiquidity(uint256 minLiquidity, uint256 maxTokens, uint256 deadline) external payable returns (uint256) {
        require(deadline > block.timestamp && maxTokens > 0 && msg.value > 0, "Invalid input");
        uint256 totalLiquidity = totalSupply;
        if (totalLiquidity > 0) {
            require(minLiquidity > 0, "Invalid min liquidity");
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = IERC20(token).balanceOf(address(this));
            uint256 tokenAmount = msg.value * tokenReserve / ethReserve + 1;
            uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
            require(maxTokens >= tokenAmount && liquidityMinted >= minLiquidity, "Invalid amounts");
            balances[msg.sender] += liquidityMinted;
            totalSupply = totalLiquidity + liquidityMinted;
            require(IERC20(token).transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
            emit AddLiquidity(msg.sender, msg.value, tokenAmount);
            emit Transfer(address(0), msg.sender, liquidityMinted);
            return liquidityMinted;
        } else {
            //remove all conditions
            //require(factory != IFactory(address(0)) && token != address(0) && msg.value >= 1000000000, "Invalid setup");
            
            require(factory.getExchange(token) == address(this), "Invalid exchange");
            uint256 tokenAmount = maxTokens;
            uint256 initialLiquidity = address(this).balance;
            totalSupply = initialLiquidity;
            balances[msg.sender] = initialLiquidity;
            require(IERC20(token).transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
            emit AddLiquidity(msg.sender, msg.value, tokenAmount);
            emit Transfer(address(0), msg.sender, initialLiquidity);
            return initialLiquidity;
        }
    }

    function removeLiquidity(uint256 amount, uint256 minEth, uint256 minTokens, uint256 deadline) external returns (uint256, uint256) {
        require(amount > 0 && deadline > block.timestamp && minEth > 0 && minTokens > 0, "Invalid input");
        uint256 totalLiquidity = totalSupply;
        require(totalLiquidity > 0, "No liquidity");
        uint256 tokenReserve = IERC20(token).balanceOf(address(this));
        uint256 ethAmount = amount * address(this).balance / totalLiquidity;
        uint256 tokenAmount = amount * tokenReserve / totalLiquidity;
        require(ethAmount >= minEth && tokenAmount >= minTokens, "Invalid amounts");
        balances[msg.sender] -= amount;
        totalSupply = totalLiquidity - amount;
        payable(msg.sender).transfer(ethAmount);
        require(IERC20(token).transfer(msg.sender, tokenAmount), "Transfer failed");
        emit RemoveLiquidity(msg.sender, ethAmount, tokenAmount);
        emit Transfer(msg.sender, address(0), amount);
        return (ethAmount, tokenAmount);
    }

    function getInputPrice(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 numerator = inputAmount * outputReserve;
        uint256 denominator = (inputReserve) + inputAmount;
        return numerator / denominator;
    }

    function getOutputPrice(uint256 outputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 numerator = inputReserve * outputAmount;
        uint256 denominator = (outputReserve - outputAmount);
        return numerator / denominator + 1;
    }

    function ethToTokenInput(uint256 ethSold, uint256 minTokens, uint256 deadline, address buyer) private returns (uint256) {
        require(deadline >= block.timestamp && ethSold > 0 && minTokens > 0, "Invalid input");
        uint256 tokenReserve = IERC20(token).balanceOf(address(this));
        uint256 tokensBought = getInputPrice(ethSold, address(this).balance - ethSold, tokenReserve);
        require(tokensBought >= minTokens, "Invalid output");
        require(IERC20(token).transfer(buyer, tokensBought), "Transfer failed");
        emit TokenPurchase(buyer, ethSold, tokensBought);
        return tokensBought;
    }

    receive() external payable {
        ethToTokenInput(msg.value, 1, block.timestamp, msg.sender);
    }

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable returns (uint256) {
        return ethToTokenInput(msg.value, minTokens, deadline, msg.sender);
    }

    function tokenToEthInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address buyer) private returns (uint256) {
        require(deadline >= block.timestamp && tokensSold > 0 && minEth > 0, "Invalid input");
        uint256 tokenReserve = IERC20(token).balanceOf(address(this));
        uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
        require(ethBought >= minEth, "Invalid output");
        payable(buyer).transfer(ethBought);
        require(IERC20(token).transferFrom(buyer, address(this), tokensSold), "Transfer failed");
        emit EthPurchase(buyer, tokensSold, ethBought);
        return ethBought;
    }

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline) external returns (uint256) {
        return tokenToEthInput(tokensSold, minEth, deadline, msg.sender);
    }

    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256) {
        require(ethSold > 0, "Invalid input");
        uint256 tokenReserve = IERC20(token).balanceOf(address(this));
        return getInputPrice(ethSold, address(this).balance, tokenReserve);
    }

    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256) {
        require(tokensSold > 0, "Invalid input");
        uint256 tokenReserve = IERC20(token).balanceOf(address(this));
        uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
        return ethBought;
    }

    function tokenAddress() external view returns (address) {
        return token;
    }

    function factoryAddress() external view returns (address) {
        return address(factory);
    }

    // Returns the balance of an address
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Transfers tokens from the sender to another address
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Transfers tokens from one address to another on behalf of the sender
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Approves another address to spend tokens on behalf of the sender
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns the remaining number of tokens that `_spender` is allowed to spend on behalf of `_owner`
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

}