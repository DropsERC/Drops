//SPDX-Lisence-Identifier: MIT

/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀.⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠛⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 

Drops Lock Marketplace is the first locked liquidity marketplace.
This smart contract is our Pinksale Liquidity Lock marketplace.

https://drops.site
https://t.me/dropserc
https://x.com/dropserc

$DROPS token address [ERC20] -> 0xA562912e1328eEA987E04c2650EfB5703757850C

*/

pragma solidity ^0.8.0;
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface IPinkLock02 {
    function transferLockOwnership(
        uint256 lockId,
        address newOwner
    )
        external;
    function getLockById(
        uint256 lockId
    ) 
        external view returns(
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            string calldata
        );
}
    
contract DropsPinksaleBscMarketplace is Ownable, ReentrancyGuard {

    // Zero address constant
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    // Pinksale locker address
    IPinkLock02 public pinkLock;

    address payable public feeWallet;
    uint256 public listingCount;
    address public marketplaceOwner;
    uint256 public activeListings;
    uint256 public listedLPsCount;
    uint256 public bnbFee;
    uint256 public referralBonus;

    struct Listing {
        uint256 lockID;
        uint256 listingID;
        address payable seller;
        address lpAddress;
        uint256 priceInBNB;
        uint256 listDate;
        bool isActive;
        bool isSold;
        address payable referral;
        bool isVerified;
    }

    struct ListingDetail {
        uint256 lockID;
        address lpAddress;
    }

    mapping(address => mapping(uint256 => Listing)) public lpToLockID;
    // Deal with listingDetail
    mapping(uint256 => ListingDetail) public listingDetail;
    mapping(address => bool) public isLPListed;

    // Relevant events
    event LockPurchasedWithBNB(
        address lpToken,
        uint256 lockID,
        uint256 profitInBNB,
        uint256 feeBNB
    );
    event ListingInitiated(
        address lpToken, 
        uint256 lockID, 
        address seller);
    event NewActiveListing(
        address lpToken,
        uint256 lockID,
        uint256 priceInBNB
    );
    event LockVerified(
        address lpToken, 
        uint256 lockID, 
        bool status);
    event ListingRedacted(
        address lpToken,
        uint256 lockID,
        address seller
    );
    event ListingWithdrawn(address lpToken, uint256 lockID);
    event FeeAddressUpdated(address _feeWallet);
    event LockerAddressUpdated(address _lockerAddress);
    event ChangedBNBFee(uint256 _bnbFee);

    /// @notice Initialize the contract with Uniswap V2 Locker, Fee Wallet, and Drops Token addresses
    /// @dev Sets the contract's dependencies and the owner upon deployment
    /// @param _pinkLock Address of the Uniswap V2 Locker contract
    /// @param _feeWallet Address of the wallet where fees will be collected
    constructor(
        address _pinkLock,
        address payable _feeWallet
    ) Ownable(msg.sender) {
        pinkLock = IPinkLock02(_pinkLock);
        feeWallet = _feeWallet;
        marketplaceOwner = msg.sender;
        bnbFee = 10;
        referralBonus = 3;
    }

    /// @notice Set the bnb fee (in percentage)
    /// @dev This function can only be called by the contract owner
    /// @param _bnbFee Fee percentage for buyLockWithBNB
    function setBNBFee(uint256 _bnbFee) external onlyOwner {
        require(_bnbFee < 10, "Maximum fee is 10%");
        require(bnbFee != _bnbFee, "You must change the fee");
        bnbFee = _bnbFee;
        emit ChangedBNBFee(_bnbFee);
    }

    /// @notice Set the address of the fee wallet
    /// @dev This function can only be called by the contract owner
    /// @param _feeWallet The address of the new fee wallet
    function setFeeWallet(address payable _feeWallet) external onlyOwner {
        require(feeWallet != _feeWallet, "Same wallet");
        require(
            _feeWallet != zeroAddress,
            "Cant set fee wallet as zero address"
        );
        feeWallet = _feeWallet;
        emit FeeAddressUpdated(_feeWallet);
    }

    /// @notice Set the address of the liquidity locker
    /// @dev This function can only be called by the contract owner
    /// @param _pinkLock The address of the new liquidity locker
    function setLockerAddress(address _pinkLock) external onlyOwner {
        require(
            address(pinkLock) != _pinkLock,
            "Must input different contract address"
        );
        require(
            _pinkLock != zeroAddress,
            "Cant set locker address as zero address"
        );
        pinkLock = IPinkLock02(_pinkLock);
        emit LockerAddressUpdated(_pinkLock);
    }

    function initiateListing(
        address lpAddress,
        uint256 lockId,
        uint256 priceInBNB,
        address payable referral
    ) external {
        (,address _lpAddress,address owner,,,,,,,,) = pinkLock.getLockById(lockId);
        require(_lpAddress == lpAddress, "Invalid LP address");
        require(msg.sender == owner, "You do not own this lock");
        require((priceInBNB > 0), "Must set a lock price in BNB");
        Listing memory tempListing = lpToLockID[_lpAddress][lockId];
        if (tempListing.listingID == 0) {
            listingCount++;
            listingDetail[listingCount] = ListingDetail(lockId, _lpAddress);
        }
        lpToLockID[_lpAddress][lockId] = Listing(
            lockId,
            listingCount,
            payable(msg.sender),
            lpAddress,
            priceInBNB,
            block.timestamp,
            false,
            false,
            referral,
            false
        );
        if (!isLPListed[_lpAddress]) {
            isLPListed[_lpAddress] = true;
            listedLPsCount++;
        }
        emit ListingInitiated(_lpAddress, lockId, msg.sender);
    }

    /// @notice Activate an initiated listing
    /// @dev The seller must have transfered lock ownership to address(this)
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lockID (per lpAddress) of the lock
    function activateListing(address lpAddress, uint256 lockID) external {
        Listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.seller == msg.sender, "Lock doesnt belong to you.");
        require(!tempListing.isActive, "Listing already active.");
        require(!tempListing.isSold, "Listing already sold.");
        (,address _lpAddress,address owner,,,,,,,,) = pinkLock.getLockById(lockID);
        require(owner == address(this), "Lock ownership not yet transferred.");
        require(_lpAddress == lpAddress, "Invalid LP address");
        lpToLockID[lpAddress][lockID].isActive = true;
        activeListings++;
        emit NewActiveListing(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInBNB
        );
    }

    function fetchListing(
        address lpAddress,
        uint256 lockID
    ) external view returns (Listing memory) {
        return (lpToLockID[lpAddress][lockID]);
    }

    /// @notice Purchase a listed LP token lock with Drops tokens
    /// @dev Requires approval to transfer Drops tokens to cover the purchase price
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function buyLockWithBNB(
        address lpAddress,
        uint256 lockID
    ) external payable nonReentrant {
        Listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInBNB > 0, "Listing not for sale in BNB.");
        require(
            msg.value == tempListing.priceInBNB,
            "Incorrect amount of BNB."
        );

        uint256 feeAmount = msg.value / bnbFee;
        uint256 toPay = msg.value - feeAmount;

        if (tempListing.referral != zeroAddress) {
            uint256 feeForReferral = (feeAmount * referralBonus) / bnbFee;
            feeAmount = feeAmount - feeForReferral;
            tempListing.referral.transfer(feeForReferral);
            feeWallet.transfer(feeAmount);
        } else {
            feeWallet.transfer(feeAmount);
        }

        payable(tempListing.seller).transfer(toPay);

        lpToLockID[lpAddress][lockID].isActive = false;
        lpToLockID[lpAddress][lockID].isSold = true;
        activeListings--;

        pinkLock.transferLockOwnership(
            lockID,
            payable(msg.sender)
        );

        emit LockPurchasedWithBNB(
            tempListing.lpAddress,
            tempListing.lockID,
            toPay,
            feeAmount
        );
    }

    /// @notice Withdraw a listed LP token lock
    /// @dev Only the seller can withdraw the listing
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function withdrawListing(
        address lpAddress,
        uint256 lockID
    ) external nonReentrant {
        Listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        (,address _lpAddress,address owner,,,,,,,,) = pinkLock.getLockById(lockID);
        require(owner == address(this), "Marketplace does not own your lock");

        if (tempListing.isActive) {
            delete lpToLockID[lpAddress][lockID];
            activeListings--;
        }

        pinkLock.transferLockOwnership(
            lockID,
            payable(msg.sender)
        );
        emit ListingWithdrawn(lpAddress, lockID);
    }

    /// @notice Verify a listing as safe
    /// @dev Only dev can verify listings
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAdress) of the lock
    /// @param status Status of verification
    function verifyListing(
        address lpAddress, 
        uint256 lockID,
        bool status) external onlyOwner {
            Listing storage tempListing = lpToLockID[lpAddress][lockID];
            require(status != tempListing.isVerified, "Must change listing status");
            tempListing.isVerified = true;
            emit LockVerified(lpAddress, lockID, status);
    }

    /// @notice Change the BNB price of a listing
    /// @dev Only seller can change price
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInBNB Updated BNB price of listing
    function changePriceInBNB(
        address lpAddress,
        uint256 lockID,
        uint256 newPriceInBNB
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        tempListing.priceInBNB = newPriceInBNB;
    }

    /// @notice Return ownership of a lock to the original seller and remove the listing
    /// @dev Only the contract owner can call this function
    /// @param lpAddress Address of the LP token associated with the lock
    /// @param lockID The ID of the lock to be redacted
    function redactListing(address lpAddress, uint256 lockID) external onlyOwner {
        Listing storage listing = lpToLockID[lpAddress][lockID];

        require(listing.seller != address(0), "Listing does not exist.");

        pinkLock.transferLockOwnership(
            lockID,
            payable(listing.seller)
        );
        
        if (listing.isActive) {
            listing.isActive = false;
            activeListings--;
        }

        delete lpToLockID[lpAddress][lockID];
        emit ListingRedacted(lpAddress, lockID, listing.seller);
    }

}