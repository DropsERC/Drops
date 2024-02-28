# Drops ERC
Drops is an ERC20, token-integrated locked liquidity marketplace, allowing;
- Holders to stabilize token price via staking and liquidity provision in return for a share of total platform revenues.
- Marketplace users to actively trade locked liquidity, a once illiquid asset.

Below is a breakdown of our two main smart contracts, [LPMarketplace.sol](contracts/LPMarketplace.sol) and [Drops.sol](contracts/Drops.sol).

# [LPMarketplace.sol](contracts/LPMarketplace.sol)

## Description
LPMarketplace is a decentralized platform built on the Ethereum blockchain, enabling users to list and sell their Uniswap V2 LP token lock ownerships. It provides a secure and transparent way for users to trade LP token locks that are locked through Unicrypt.

## Features
- List LP token locks for sale.
- Purchase LP token locks with ETH or Drops tokens.
- Secure and non-reentrant contract design.
- Transfer ownership of LP token locks.

## Prerequisites
- Solidity ^0.8.0
- OpenZeppelin Contracts

## Installation
Clone the repository:
~ git clone [repository link]

Install dependencies:
- Ownable.sol - Openzeppelin
- IERC20.sol - Openzeppelin
- ReentrancyGuard.sol - Openzeppelin

## Usage
To use the LPMarketplace contract:
1. Deploy the contract with necessary parameters - Uniswap V2 Locker address, Fee Wallet address, and Drops Token address.
2. Use `initiateListing` to list an LP token lock for sale.
3. Transfer Unicrypt lock ownership to marketplace contract.
4. Activate a listing with `activateListing`.
5. Purchase a listed lock with `buyLockWithETH` or `buyLockWithDrops`.
6. [IF NECESSARY] withdraw your listing and retrieve lock ownership at any time.

## Contract Methods
- `setDropsToken`: Set the address of the Drops token.
- `setFeeWallet`: Set the address of the fee wallet.
- `setLockerAddress`: Set the address of the locker contract (Unicrypt).
- `initiateListing`: List an LP token lock for sale.
- `activateListing`: Activate an initiated listing.
- `buyLockWithETH`: Purchase a listed LP token lock with ETH.
- `buyLockWithDrops`: Purchase a listed LP token lock with Drops tokens.
- `withdrawListing`: Withdraw a listed LP token lock.
- `changePriceInETH`: Change the ETH price of a listing.
- `changePriceInDrops`: Change the Drops token price of a listing.

# [Drops.sol](contracts/Drops.sol)

## Description
The Drops Token Contract is an ERC20 token smart contract built on Ethereum. It integrates with Uniswap for liquidity provision and includes features like swap-and-liquify, trading controls, and dynamic taxation for transactions.

## Features
- ERC20 standard compliance.
- Integration with Uniswap V2 for liquidity management.
- Swap-and-liquify mechanism to maintain liquidity pool health.
- Adjustable taxation for buy/sell transactions to benefit liquidity and project funding.
- Trading controls to regulate buy/sell actions.
- Withdrawal functions for ETH and ERC20 tokens.

## Prerequisites
- Solidity 0.8.20
- OpenZeppelin Contracts

## Setup and Installation
1. Clone the repository:
~ git clone [repository link]

2. Install necessary dependencies:
Openzeppelin:
- Ownable.sol
- ERC20.sol
- IERC20.sol
  
Uniswap v2-core:
- IUniswapV2Factory.sol
  
Uniswap v2-periphery:
- IUniswapV2Router02.sol

## Contract Deployment
1. Compile the contract using Solidity 0.8.20.
2. Deploy the contract to the Ethereum network using tools like Truffle, Hardhat, or Brownie.
3. Initialize the contract with the appropriate parameters such as the Uniswap router address, fee wallet, and tax rates.

## Important Contract Functions
- `swapAndLiquify`: Converts tokens into ETH and adds them to the liquidity pool - used to collect fees.
- `addLiquidity`: Adds liquidity to Uniswap pool.
- `swapTokensForETH`: Swaps tokens for ETH.
- `setSellBuyTax`: Adjusts the taxation rates for transactions.
- `setTradingOpen`: Enables trading on the token.
- `setPurchaseLimit`: Sets the maximum amount that can be purchased.
- `setSwapAndLiqThreshold`: Sets the threshold for swap-and-liquify.
- `excludeFromLimitation`: Excludes an account from transaction limitations.
- `withdrawETH`: Withdraws ETH from the contract.
- `withdrawERC20Token`: Withdraws ERC20 tokens from the contract.

## Contributing
No contributions will be accepted.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

