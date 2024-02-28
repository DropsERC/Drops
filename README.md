# LPMarketplace

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
~ git clone [link]
Install dependencies:
Openzeppelin contracts


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

## Contributing
No contributions will be accepted.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

