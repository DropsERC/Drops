# Test Script for Drops ERC Contracts

This README details the usage and setup of the test script designed to validate the functionality of the `LPMarketplace.sol` and `Drops.sol` contracts in the Drops ERC project.

## Description

The test script is a Python script that interacts with the deployed smart contracts of the Drops ERC project. It is intended to test the basic buy/sell functionality of the Drops liquidity marketplace. The script goes through the complete flow from approving token spending to executing a purchase on the marketplace.

## Prerequisites

- [Python](https://www.python.org/downloads/) (version 3.7 or higher)
- [Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html) Ethereum development framework
- Access to an Ethereum mainnet (CAN BE USED ON TESTNET AS WELL) (e.g., Goerli) and ETH
- [Node.js and npm](https://nodejs.org/en/download/) (for Ethereum package management)

## Setup

1. Clone the repository [https://github.com/DropsERC/Drops.git]
2. Navigate to the test script directory test/test.py
3. Install Brownie, if not already installed. You can install it using pip: pip install eth-brownie

## Configuration

1. Create a `.env` file in the script directory with the following variables:
- export SELLER_PK='your_seller_private_key'
- export BUYER_PK='your_buyer_private_key'

Replace `your_seller_private_key` and `your_buyer_private_key` with the appropriate private keys.

2. Ensure you have sufficient ETH in your test accounts for gas fees.

## Usage

Run the script using Brownie:
~ brownie run test.py --network [NETWORK] // Replace NETWORK with mainnet or goerli

## Test Flow

The script will:

1. Approve the spending of LP tokens.
2. Lock liquidity in the Unicrypt locker.
3. Initiate a listing on the Drops marketplace.
4. Transfer lock ownership.
5. Activate the listing.
6. Purchase the lock using ETH.

## Assertions

The script contains assertions to verify that each step is completed successfully. These assertions ensure that the contract state changes as expected after each transaction.

## Contributing

This test script is part of the Drops ERC project. No external contributions are being accepted for this script.

## License

This script is licensed under the MIT License - see the [LICENSE](LICENSE) file in the main repository for details.


