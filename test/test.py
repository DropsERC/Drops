from brownie import DropsLockMarketplace, accounts, network, Contract
import os

"""
Script to test buy/sell functionality on the Drops marketplace.
This script covers the entire process from approving token spending to final purchase.
"""

# Constants
UNCX_ADDRESS = '0x54f33FbDcfDDaCA64361f82BE1471b342Fc5f640'
LP_ADDRESS = 'ADDRESS OF LP TOKEN TO LOCK & LIST'
SELLER_ADDRESS = 'ADDRESS OF THE LOCK OWNER'
MARKETPLACE_ADDRESS = '0xC886FF9dfEE4b34E3D0CAAb3eb802D9525D3DCcb'

def get_contract(contract_address, contract_name):
    """
    Fetches a contract instance.
    :param contract_address: Address of the contract.
    :param contract_name: Name of the contract.
    :return: Contract instance.
    """
    contract_abi = Contract.from_explorer(contract_address)
    return Contract.from_abi(contract_name, contract_address, contract_abi.abi)

def get_account(key_name):
    """
    Fetches an account instance using a key name from the .env file.
    :param key_name: The environment variable key name.
    :return: Account instance.
    """
    return accounts.add(os.getenv(key_name))

def main():
    """
    Main function to execute the test steps.
    """
    # Initialize contracts and accounts
    seller = get_account("SELLER_PK")
    buyer = get_account("BUYER_PK")
    Drops = get_contract(MARKETPLACE_ADDRESS, 'DropsLockMarketplace')
    lp_contract = get_contract(LP_ADDRESS, "UniswapV2Pair")
    locker_contract = get_contract(UNCX_ADDRESS, "UniswapV2Locker")

    # Approve token spending and lock liquidity
    lp_balance = lp_contract.balanceOf(seller.address, {"from": seller})
    print(f"LP balance: {lp_balance}")
    lp_contract.approve(UNCX_ADDRESS, lp_balance, {"from": seller})
    locker_contract.lockLPToken(LP_ADDRESS, lp_balance, 110000, 
                                '0x0000000000000000000000000000000000000000', 
                                True, SELLER_ADDRESS, 
                                {"from": seller, "value": 1e16})

    # Other steps for listing, transferring lock ownership, and purchase
    # lock_id and index may vary, ensure these are correct
    lock_id = 0  # Modify as necessary
    index = 0    # Modify as necessary
    price_in_eth = 1e16  # 0.01 ETH
    Drops.initiateListing(LP_ADDRESS, lock_id, price_in_eth, price_in_eth, 
                          SELLER_ADDRESS, {"from": seller})
    locker_contract.transferLockOwnership(LP_ADDRESS, index, lock_id, Drops.address, 
                                          {"from": seller})
    Drops.activateListing(LP_ADDRESS, lock_id, {"from": seller})
    Drops.buyLockWithETH(LP_ADDRESS, lock_id, {"from": buyer, "value": price_in_eth})


if __name__ == "__main__":
    main()
