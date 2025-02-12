// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IExchange.sol';
import './ExchangeV2.sol';
import './interfaces/IFactory.sol';

contract Factory {
    event NewExchange(address indexed token, address indexed exchange);

    uint256 public tokenCount;
    mapping(address => address) public tokenToExchange;
    mapping(address => address) public exchangeToToken;
    mapping(uint256 => address) public idToToken;

    function createExchange(address token) external returns (address) {
        require(token != address(0), "Invalid token address");
        require(tokenToExchange[token] == address(0), "Exchange already exists");

        ExchangeV2 exchange = new ExchangeV2(token);
        address exchangeAddress = address(exchange);

        tokenToExchange[token] = exchangeAddress;
        exchangeToToken[exchangeAddress] = token;
        uint256 tokenId = tokenCount + 1;
        tokenCount = tokenId;
        idToToken[tokenId] = token;

        emit NewExchange(token, exchangeAddress);
    }

    function getExchange(address token) external view returns (address) {
        return tokenToExchange[token];
    }

    function getToken(address exchange) external view returns (address) {
        return exchangeToToken[exchange];
    }

    function getTokenWithId(uint256 tokenId) external view returns (address) {
        return idToToken[tokenId];
    }

}