//SPDX-Liscence-Identifier: MIT
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

interface IUniswapV2Locker {
    // Getter function to fetch details about a specific lock for a user
    function getUserLockForTokenAtIndex(address user, address lpAddress, uint256 index) external view returns (uint256, uint256, uint256, uint256,uint256,address);
    function tokenLocks(address lpAddress, uint256 lockID) external view returns (uint256, uint256, uint256, uint256, uint256, address);
    // Function to transfer the ownership of a lock
    function transferLockOwnership(address lpAddress, uint256 index, uint256 lockID, address payable newOwner) external;
    function getUserNumLocksForToken (address _user, address _lpAddress) external view returns (uint256);
} 

/// @title Marketplace for LP Token Lock Ownership
/// @notice This contract allows users to list and sell their Uniswap V2 LP token lock ownerships locked through Unicrypt.
contract LPMarketplace is Ownable, ReentrancyGuard {

    // Unicrypt V2 Locker address
    IUniswapV2Locker public uniswapV2Locker;

    // Native Drops token address
    IERC20 public dropsToken;
    address payable public feeWallet;
    uint256 listingCount;
    address public marketplaceOwner;
    uint256 public activeListings;

    // Zero address constant
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    // lpAddress + lockID -> returns listing
    mapping(address => mapping(uint256 => listing)) public lpToLockID;

    // lpAddress -> listing[] associated to lpAddress
    mapping(address => listing[]) public lpToListings; 

    // Relevant listing info
    struct listing {
        uint256 lockID;
        address payable seller;
        address lpAddress;
        uint256 priceInETH;
        uint256 priceInDrops;
        bool isActive;
        bool isSold;
    }

    // Relevant events
    event lockPurchasedWithETH(address lpToken, uint256 lockID, uint256 profitInETH, uint256 feeETH);
    event lockPurchasedWithDrops(address lpToken, uint256 lockID, uint256 profitInDrops);
    event listingInitiated(address lpToken, uint256 lockID, address seller);
    event newActiveListing(address lpToken, uint256 lockID, uint256 priceInETH, uint256 priceInDrops);
    event listingWithdrawn(address lpToken, uint256 lockID);
    event setDropsAddress(address _dropsAddress);
    event setFeeAddress(address _feeWallet);
    event setLockerAddress(address _lockerAddress);

    /// @title Constructor for the LPMarketplace contract
    /// @notice Initialize the contract with Uniswap V2 Locker, Fee Wallet, and Drops Token addresses
    /// @dev Sets the contract's dependencies and the owner upon deployment
    /// @param _uniswapV2Locker Address of the Uniswap V2 Locker contract
    /// @param _feeWallet Address of the wallet where fees will be collected
    /// @param _dropsTokenAddress Address of the Drops token contract
    constructor(address _uniswapV2Locker, address payable _feeWallet, address _dropsTokenAddress) Ownable(msg.sender) {
        uniswapV2Locker = IUniswapV2Locker(_uniswapV2Locker);
        feeWallet = _feeWallet;
        marketplaceOwner = msg.sender;
        dropsToken = IERC20(_dropsTokenAddress);
    }

    /// @notice Set the address of the Drops token
    /// @dev This function can only be called by the contract owner
    /// @param _dropsTokenAddress The address of the Drops token contract
    function setDropsToken(address _dropsTokenAddress) external onlyOwner {
            require(address(dropsToken) != _dropsTokenAddress, "Must input different contract address");
            require(_dropsTokenAddress != zeroAddress, "Cant set drops address as zero address" );
            dropsToken = IERC20(_dropsTokenAddress);
            emit setDropsAddress(_dropsTokenAddress);
    }
    
    /// @notice Set the address of the fee wallet
    /// @dev This function can only be called by the contract owner
    /// @param _feeWallet The address of the new fee wallet
    function setFeeWallet(address payable _feeWallet) external onlyOwner {
        require(feeWallet != _feeWallet, "Same wallet");
        require(_feeWallet != zeroAddress, "Cant set fee wallet as zero address" );
        feeWallet = _feeWallet;
        emit setFeeAddress(_feeWallet);
    }

    /// @notice Set the address of the locker contract (Unicrypt)
    /// @dev This function can only be called by the contract owner
    /// @param _uniswapV2Locker The address of the locker contract (Unicrypt)
    function setLockerAddress (address _uniswapV2Locker) external onlyOwner {
        require(address(uniswapV2Locker) != _uniswapV2Locker, "Must input different contract address");
        require(_uniswapV2Locker != zeroAddress, "Cant set locker address as zero address" );
        uniswapV2Locker = IUniswapV2Locker(_uniswapV2Locker);
        emit setLockerAddress(_uniswapV2Locker);
    }

    /// @notice List an LP token lock for sale
    /// @dev The seller must be the owner of the lock and approve this contract to manage the lock
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    /// @param priceInETH The selling price in ETH
    /// @param priceInDrops The selling price in Drops tokens
    function initiateListing(address lpAddress, uint256 lockID, uint256 _priceInETH, uint256 _priceInDrops) external {
        ( , , , , , address owner) = uniswapV2Locker.tokenLocks(lpAddress, lockID);
        require(msg.sender == owner, "You dont own that lock.");
        require((_priceInETH > 0) || (_priceInDrops > 0), "You must set a price in Drops or ETH");
        lpToLockID[lpAddress][lockID] = listing(lockID, payable(msg.sender), lpAddress, _priceInETH, _priceInDrops, false, false);
        listingCount++;
        emit listingInitiated(lpAddress, lockID, msg.sender);
    }

    /// @notice Activate an initiated listing
    /// @dev The seller must have transfered lock ownership to address(this)
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lockID (per lpAddress) of the lock
    function activateListing(address lpAddress, uint256 lockID) external {
        listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.seller == msg.sender, "Lock doesnt belong to you.");
        require(!tempListing.isActive, "Listing already active.");
        require(!tempListing.isSold, "Listing already sold.");
        ( , , , , , address owner) = uniswapV2Locker.tokenLocks(lpAddress, lockID);
        require(owner == address(this), "Lock ownership not yet transferred.");
        lpToLockID[lpAddress][lockID].isActive = true;
        activeListings++;
        emit newActiveListing(tempListing.lpAddress, tempListing.lockID, tempListing.priceInETH, tempListing.priceInDrops);
    }

    function fetchListing(address lpAddress, uint256 lockID) external view returns(listing memory) {
        return(lpToLockID[lpAddress][lockID]);
    }

    /// @notice Purchase a listed LP token lock with ETH 
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function buyLockWithETH(address lpAddress, uint256 lockID) external payable nonReentrant {
        listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInETH > 0, "Listing not for sale in ETH.");
        require(msg.value == tempListing.priceInETH, "Incorrect amount of ETH.");
        
        (bool lockFound, uint256 index) = _getIndex(lpAddress, tempListing);

        uint256 feeAmount = msg.value / 10;
        uint256 toPay = msg.value - feeAmount;

        feeWallet.transfer(feeAmount);
        payable(tempListing.seller).transfer(toPay);

        lpToLockID[lpAddress][lockID].isActive = false;
        lpToLockID[lpAddress][lockID].isSold = true;
        activeListings--;

        uniswapV2Locker.transferLockOwnership(lpAddress, index, lockID, payable(msg.sender));

        emit lockPurchasedWithETH(tempListing.lpAddress, tempListing.lockID, toPay, feeAmount);   
    }

    /// @notice Purchase a listed LP token lock with Drops tokens
    /// @dev Requires approval to transfer Drops tokens to cover the purchase price
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function buyLockWithDrops(address lpAddress, uint256 lockID) external payable nonReentrant{
        listing memory tempListing = lpToLockID[lpAddress][lockID];

        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInDrops > 0, "Listing not for sale in Drops.");
        require(dropsToken.balanceOf(msg.sender) > tempListing.priceInDrops, "Insufficient drops.");
        
        (bool lockFound, uint256 index) = _getIndex(lpAddress, tempListing);

        require(lockFound, "Mismatch in inputs.");

        require(dropsToken.transferFrom(msg.sender, tempListing.seller, tempListing.priceInDrops));

        lpToLockID[lpAddress][lockID].isActive = false;
        lpToLockID[lpAddress][lockID].isSold = true;
        activeListings--;

        uniswapV2Locker.transferLockOwnership(lpAddress, index, lockID, payable(msg.sender));

        emit lockPurchasedWithDrops(tempListing.lpAddress, tempListing.lockID, tempListing.priceInDrops);
    }

    /// @notice Find unique (per lpAddress) lock index in order to transfer lock ownership
    /// @param _lpAddress Address of the LP token
    /// @param _listing Listing in question
    function _getIndex(address _lpAddress, Listing memory _listing) internal nonReentrant {
        uint256 index;
        uint256 numLocksAtAddress = uniswapV2Locker.getUserNumLocksForToken(address(this), _lpAddress);
        bool lockFound = false;
        
        if (numLocksAtAddress == 1) {
            index = 0;
            lockFound = true;
        }
        else {
            for(index = 0; index < numLocksAtAddress; index++) {
                ( , , , ,uint256 _lockID, ) = uniswapV2Locker.getUserLockForTokenAtIndex(address(this), _lpAddress, index);
                if (_lockID == _listing.lockID) {
                    lockFound = true;
                    break;
                }
            }
        }
        return(index,lockFound);
    }

    /// @notice Withdraw a listed LP token lock
    /// @dev Only the seller can withdraw the listing
    /// @param lpAddress Address of the LP token
    /// @param lockID The ID of the lock
    function withdrawListing(address lpAddress, uint256 lockID) external nonReentrant {
        listing memory tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.seller == msg.sender, "This listing does not belong to you.");

        ( , , , , , address owner) = uniswapV2Locker.tokenLocks(lpAddress, lockID);
        require(owner == address(this), "Marketplace does not own your lock");

       (bool lockFound, uint256 index) = _getIndex(lpAddress, tempListing);

        require(lockFound, "Mismatch in inputs.");

        if (tempListing.isActive) {
            lpToLockID[lpAddress][lockID].isActive = false;
            activeListings--;
        }

        uniswapV2Locker.transferLockOwnership(lpAddress, index, lockID, payable(msg.sender));

        emit listingWithdrawn(lpAddress, lockID);
    }

    /// @notice Change the ETH price of a listing
    /// @dev Only seller can change price
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInETH Updated ETH price of listing
    function changePriceInETH(address lpAddress, uint256 lockID, uint256 newPriceInETH) external nonReentrant {
        listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.seller == msg.sender, "This listing does not belong to you.");
        tempListing.priceInETH = newPriceInETH;
    }

    /// @notice Change the price of a listing in Drops
    /// @dev Only seller can change price
    /// @param lpAddress Address of the LP token
    /// @param lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInDrops Updated Drops price of listing
    function changePriceInDrops(address lpAddress, uint256 lockID, uint256 newPriceInDrops) external nonReentrant {
        listing storage tempListing = lpToLockID[lpAddress][lockID];
        require(tempListing.seller == msg.sender, "This listing does not belong to you.");
        tempListing.priceInDrops = newPriceInDrops;
    }
}