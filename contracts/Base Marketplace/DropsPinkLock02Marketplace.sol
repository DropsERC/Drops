//SPDX-License-Identifier: MIT

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
This smart contract is our Unicrypt LP lock marketplace.

https://drops.site
https://t.me/dropserc
https://x.com/dropserc

$DROPS token address -> 0xA562912e1328eEA987E04c2650EfB5703757850C
 
*/

pragma solidity ^0.8.0;
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface IPinkLock02 {
    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate;
        uint256 tgeDate; // TGE date for vesting locks, unlock date for normal locks
        uint256 tgeBps; // In bips. Is 0 for normal locks
        uint256 cycle; // Is 0 for normal locks
        uint256 cycleBps; // In bips. Is 0 for normal locks
        uint256 unlockedAmount;
        string description;
    }

    function transferLockOwnership(uint256 lockId, address newOwner) external;

    function getLockById(uint256 lockId) external view returns (Lock memory);
}

contract PinksaleMart is Ownable, ReentrancyGuard {
    // Zero address constant
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    // Pinksale locker address
    IPinkLock02 public pinkLock;
    // Drops token address
    IERC20 public dropsToken;

    address payable public feeWallet;
    uint256 public listingCount;
    address public marketplaceOwner;
    uint256 public activeListings;
    uint256 public listedLPsCount;
    uint256 public ethFee;
    uint256 public referralBonus;

    struct Listing {
        uint256 lockID;
        uint256 listingID;
        address payable seller;
        address lpAddress;
        uint256 priceInETH;
        uint256 priceInDrops;
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
    event LockPurchasedWithETH(
        address lpToken,
        uint256 lockID,
        uint256 profitInETH,
        uint256 feeETH
    );
    event LockPurchasedWithDrops(
        address lpToken,
        uint256 lockID,
        uint256 profitInDrops
    );
    event ListingInitiated(address lpToken, uint256 lockID, address seller);
    event NewActiveListing(
        address lpToken,
        uint256 lockID,
        uint256 priceInETH,
        uint256 priceInDrops
    );
    event LockVerified(address lpToken, uint256 lockID, bool status);
    event ListingRedacted(address lpToken, uint256 lockID, address seller);
    event ListingWithdrawn(address lpToken, uint256 lockID);
    event DropsAddressUpdated(address _dropsAddress);
    event FeeAddressUpdated(address _feeWallet);
    event LockerAddressUpdated(address _lockerAddress);
    event ChangedETHFee(uint256 _ethFee);

    /// @notice Initialize the contract with Uniswap V2 Locker, Fee Wallet, and Drops Token addresses
    /// @dev Sets the contract's dependencies and the owner upon deployment
    /// @param _pinkLock Address of the Uniswap V2 Locker contract
    /// @param _feeWallet Address of the wallet where fees will be collected
    /// @param _dropsToken Address of the Drops token contract
    constructor(
        address _pinkLock,
        address payable _feeWallet,
        address _dropsToken
    ) Ownable(msg.sender) {
        pinkLock = IPinkLock02(_pinkLock);
        feeWallet = _feeWallet;
        marketplaceOwner = msg.sender;
        dropsToken = IERC20(_dropsToken);
        ethFee = 10;
        referralBonus = 3;
    }

    /// @notice Set the eth fee (in percentage)
    /// @dev This function can only be called by the contract owner
    /// @param _ethFee Fee percentage for buyLockWithETH
    function setETHFee(uint256 _ethFee) external onlyOwner {
        require(_ethFee < 10, "Maximum fee is 10%");
        require(ethFee != _ethFee, "You must change the fee");
        ethFee = _ethFee;
        emit ChangedETHFee(_ethFee);
    }

    /// @notice Set the address of the Drops token
    /// @dev This function can only be called by the contract owner
    /// @param _dropsTokenAddress The address of the Drops token contract
    function setDropsToken(address _dropsTokenAddress) external onlyOwner {
        require(
            address(dropsToken) != _dropsTokenAddress,
            "Must input different contract address"
        );
        require(
            _dropsTokenAddress != zeroAddress,
            "Cant set drops address as zero address"
        );
        dropsToken = IERC20(_dropsTokenAddress);
        emit DropsAddressUpdated(_dropsTokenAddress);
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
        uint256 priceInETH,
        uint256 priceInDrops,
        address payable referral
    ) external {
        IPinkLock02.Lock memory data = pinkLock.getLockById(lockId);
        address token = data.token;
        address owner = data.owner;
        require(lpAddress == token, "Invalid LP address");
        require(msg.sender == owner, "You do not own this lock");
        require(
            (priceInETH > 0) || (priceInDrops > 0),
            "Must set a lock price in Drops or ETH"
        );
        Listing memory tempListing = lpToLockID[token][lockId];
        if (tempListing.listingID == 0) {
            listingCount++;
            listingDetail[listingCount] = ListingDetail(lockId, token);
        }
        lpToLockID[token][lockId] = Listing(
            lockId,
            listingCount,
            payable(msg.sender),
            lpAddress,
            priceInETH,
            priceInDrops,
            block.timestamp,
            false,
            false,
            referral,
            false
        );
        if (!isLPListed[token]) {
            isLPListed[token] = true;
            listedLPsCount++;
        }
        emit ListingInitiated(token, lockId, msg.sender);
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
        IPinkLock02.Lock memory data = pinkLock.getLockById(lockID);
        address _lpAddress = data.token;
        address owner = data.owner;
        require(owner == address(this), "Lock ownership not yet transferred.");
        require(_lpAddress == lpAddress, "Invalid LP address");
        lpToLockID[lpAddress][lockID].isActive = true;
        activeListings++;
        emit NewActiveListing(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInETH,
            tempListing.priceInDrops
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
    function buyLockWithETH(
        address lpAddress,
        uint256 lockID
    ) external payable nonReentrant {
        Listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInETH > 0, "Listing not for sale in ETH.");
        require(
            msg.value == tempListing.priceInETH,
            "Incorrect amount of ETH."
        );

        uint256 feeAmount = msg.value / ethFee;
        uint256 toPay = msg.value - feeAmount;

        if (tempListing.referral != zeroAddress) {
            uint256 feeForReferral = (feeAmount * referralBonus) / ethFee;
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

        pinkLock.transferLockOwnership(lockID, payable(msg.sender));

        emit LockPurchasedWithETH(
            tempListing.lpAddress,
            tempListing.lockID,
            toPay,
            feeAmount
        );
    }

    /// @notice Purchase a listed LP token lock with Drops tokens
    /// @dev Requires approval to transfer Drops tokens to cover the purchase price
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function buyLockWithDrops(
        address lpAddress,
        uint256 lockID
    ) external payable nonReentrant {
        Listing memory tempListing = lpToLockID[lpAddress][lockID];

        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInDrops > 0, "Listing not for sale in Drops.");
        require(
            dropsToken.balanceOf(msg.sender) > tempListing.priceInDrops,
            "Insufficient drops."
        );

        require(
            dropsToken.transferFrom(
                msg.sender,
                tempListing.seller,
                tempListing.priceInDrops
            )
        );

        lpToLockID[lpAddress][lockID].isActive = false;
        lpToLockID[lpAddress][lockID].isSold = true;
        activeListings--;

        pinkLock.transferLockOwnership(lockID, payable(msg.sender));

        emit LockPurchasedWithDrops(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInDrops
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
        IPinkLock02.Lock memory data = pinkLock.getLockById(lockID);
        address owner = data.owner;
        require(owner == address(this), "Marketplace does not own your lock");

        if (tempListing.isActive) {
            delete lpToLockID[lpAddress][lockID];
            activeListings--;
        }

        pinkLock.transferLockOwnership(lockID, payable(msg.sender));
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
        bool status
    ) external onlyOwner {
        Listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(status != tempListing.isVerified, "Must change listing status");
        tempListing.isVerified = true;
        emit LockVerified(lpAddress, lockID, status);
    }

    /// @notice Change the ETH price of a listing
    /// @dev Only seller can change price
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInETH Updated ETH price of listing
    function changePriceInETH(
        address lpAddress,
        uint256 lockID,
        uint256 newPriceInETH
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        tempListing.priceInETH = newPriceInETH;
    }

    /// @notice Change the price of a listing in Drops
    /// @dev Only seller can change price
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInDrops Updated Drops price of listing
    function changePriceInDrops(
        address lpAddress,
        uint256 lockID,
        uint256 newPriceInDrops
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        tempListing.priceInDrops = newPriceInDrops;
    }

    /// @notice Return ownership of a lock to the original seller and remove the listing
    /// @dev Only the contract owner can call this function
    /// @param lpAddress Address of the LP token associated with the lock
    /// @param lockID The ID of the lock to be redacted
    function redactListing(
        address lpAddress,
        uint256 lockID
    ) external onlyOwner {
        Listing storage listing = lpToLockID[lpAddress][lockID];

        require(listing.seller != address(0), "Listing does not exist.");

        pinkLock.transferLockOwnership(lockID, payable(listing.seller));

        if (listing.isActive) {
            listing.isActive = false;
            activeListings--;
        }

        delete lpToLockID[lpAddress][lockID];
        emit ListingRedacted(lpAddress, lockID, listing.seller);
    }
}