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
This smart contract is our Pinklock LP lock marketplace.

https://drops.site
https://t.me/dropserc
https://x.com/dropserc

$DROPS token address -> 0xA562912e1328eEA987E04c2650EfB5703757850C
 
*/

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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

    struct CumulativeLockInfo {
        address token;
        address factory;
        uint256 amount;
    }

    function transferLockOwnership(uint256 lockId, address newOwner) external;

    function getLockById(uint256 lockId) external view returns (Lock memory);

    function cumulativeLockInfo(
        address
    ) external view returns (CumulativeLockInfo memory);
}

/// @title Marketplace for LP Token Lock Ownership
/// @notice This contract allows users to list and sell their Uniswap V2 LP token lock ownerships locked through Pinklock.
contract DropPinklockMarketplace is Ownable, ReentrancyGuard {
    // Pinklock V2 Locker address
    IPinkLock02 public pinkLockV2;

    address payable public feeWallet;
    uint256 public listingCount;
    address public marketplaceOwner;
    uint256 public activeListings;
    uint256 public listedLPsCount;
    uint256 public totalValueList;
    uint256 public ethFee;
    uint256 public referralBonus;

    // Zero address constant
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    // Relevant listing info
    struct Listing {
        uint256 lockID;
        uint256 listingID;
        address payable seller;
        address lpAddress;
        uint256 priceInETH;
        uint256 listDate;
        bool isActive;
        bool isSold;
        address payable referral;
        bool isVerified;
        bool forAuction;
        uint256 auctionIndex;
    }

    struct Bid {
        address bidder;
        uint256 ethBid;
        uint256 listingID;
    }

    struct ListingDetail {
        uint256 lockID;
        address lpAddress;
    }

    struct AuctionDetails {
        Bid topEthBid;
    }

    // lpAddress + lockID -> returns Listing
    mapping(address => mapping(uint256 => Listing)) public lpToLockID;
    mapping(uint256 => ListingDetail) public listingDetail;
    mapping(address => bool) public isLPListed;
    mapping(address => Bid[]) public userBids;
    mapping(address => mapping(uint256 => Bid[])) public lpBids;

    // Auctions:
    AuctionDetails[] auctions;
    uint256 auctionCount;

    // Relevant events
    event NewBid(
        address bidder,
        address lpAddress,
        uint256 lockID,
        uint256 bidInEth
    );
    event BidRedacted(
        address bidder,
        address lpAddress,
        uint256 lockId,
        uint bidInEth
    );
    event BidAccepted(
        address lpToken,
        uint256 lockId,
        uint256 profitInEth,
        uint256 feeEth
    );
    event LockPurchasedWithETH(
        address lpToken,
        uint256 lockID,
        uint256 profitInETH,
        uint256 feeETH
    );
    event ListingInitiated(address lpToken, uint256 lockID, address seller);
    event NewActiveListing(address lpToken, uint256 lockID, uint256 priceInETH);
    event LockVerified(address lpToken, uint256 lockID, bool status);
    event ListingRedacted(address lpToken, uint256 lockID, address seller);
    event ListingWithdrawn(address lpToken, uint256 lockID);
    event FeeAddressUpdated(address _feeWallet);
    event LockerAddressUpdated(address _lockerAddress);
    event ChangedETHFee(uint256 _ethFee);

    /// @notice Initialize the contract with Uniswap V2 Locker, Fee Wallet, and Drops Token addresses
    /// @dev Sets the contract's dependencies and the owner upon deployment
    /// @param _pinkLockV2 Address of the Uniswap V2 Locker contract
    /// @param _feeWallet Address of the wallet where fees will be collected
    constructor(
        address _pinkLockV2,
        address payable _feeWallet
    ) Ownable(msg.sender) {
        pinkLockV2 = IPinkLock02(_pinkLockV2);
        feeWallet = _feeWallet;
        marketplaceOwner = msg.sender;
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
    /// @param _pinkLockV2 The address of the new liquidity locker
    function setLockerAddress(address _pinkLockV2) external onlyOwner {
        require(
            address(pinkLockV2) != _pinkLockV2,
            "Must input different contract address"
        );
        require(
            _pinkLockV2 != zeroAddress,
            "Cant set locker address as zero address"
        );
        pinkLockV2 = IPinkLock02(_pinkLockV2);
        emit LockerAddressUpdated(_pinkLockV2);
    }

    function _initializeAuctionDetails(
        uint256 _listingId
    ) internal pure returns (AuctionDetails memory) {
        AuctionDetails memory blankAuctionDetails;
        blankAuctionDetails.topEthBid = Bid(address(0), 0, _listingId);

        return blankAuctionDetails;
    }

    function isLPToken(address _token) public view returns (bool) {
        IPinkLock02.CumulativeLockInfo memory tokenInfo = pinkLockV2
            .cumulativeLockInfo(_token);
        return tokenInfo.factory != address(0);
    }

    /// @notice List an LP token lock for sale
    /// @dev The seller must be the owner of the lock and approve this contract to manage the lock
    /// @param _lockId The ID of the lock
    /// @param _priceInETH The selling price in ETH
    function initiateListing(
        uint256 _lockId,
        uint256 _priceInETH,
        address payable _referral
    ) external {
        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(_lockId);
        address owner = _pinkLock.owner;
        address _lpAddress = _pinkLock.token;

        require(_pinkLock.token != address(0), "Mismatch in inputs");
        require(isLPToken(_lpAddress), "Not a LP token");
        require(msg.sender == owner, "You dont own that lock.");
        require(_priceInETH > 0, "You must set a price in ETH");
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];

        AuctionDetails memory tempDetails;
        if (tempListing.listingID == 0) {
            listingCount++;
            listingDetail[listingCount] = ListingDetail(_lockId, _lpAddress);
            tempDetails = _initializeAuctionDetails(listingCount);
        } else {
            tempDetails = _initializeAuctionDetails(tempListing.listingID);
        }
        auctions.push(tempDetails);

        lpToLockID[_lpAddress][_lockId] = Listing(
            _lockId,
            listingCount,
            payable(msg.sender),
            _lpAddress,
            _priceInETH,
            block.timestamp,
            false,
            false,
            _referral,
            false,
            true,
            auctionCount
        );

        auctionCount++;

        if (!isLPListed[_lpAddress]) {
            isLPListed[_lpAddress] = true;
            listedLPsCount++;
        }

        emit ListingInitiated(_lpAddress, _lockId, msg.sender);
    }

    /// @notice Bid on a listing with Ethereum - transfer ETH to CA until bid is either beat, accepted, or withdrawn
    /// @dev Bidder must not be listing owner.
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    function bidEth(address _lpAddress, uint256 _lockId) external payable {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockId];
        require(tempListing.forAuction, "Listing not for auction");
        require(
            tempListing.seller != msg.sender,
            "Unable to bid on own listing"
        );
        require(tempListing.isActive, "Listing inactive.");
        require(!tempListing.isSold, "Listing already sold.");

        AuctionDetails storage currentAuction = auctions[
            tempListing.auctionIndex
        ];

        require(
            msg.value > currentAuction.topEthBid.ethBid,
            "Must outbid current highest bid"
        );

        if (currentAuction.topEthBid.ethBid > 0) {
            payable(currentAuction.topEthBid.bidder).transfer(
                currentAuction.topEthBid.ethBid
            );
        }

        currentAuction.topEthBid = Bid(
            msg.sender,
            msg.value,
            tempListing.listingID
        );

        userBids[msg.sender].push(currentAuction.topEthBid);
        lpBids[_lpAddress][_lockId].push(currentAuction.topEthBid);
        emit NewBid(msg.sender, _lpAddress, _lockId, msg.value);
    }

    function acceptBid(
        address _lpAddress,
        uint256 _lockId
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockId];
        AuctionDetails storage tempAuction = auctions[tempListing.auctionIndex];
        require(tempListing.seller == msg.sender, "Owner can accept bid");

        Bid storage topBid = tempAuction.topEthBid;
        require(topBid.ethBid > 0, "Bid must exceed 0");

        _winAuction(tempListing, topBid);
    }

    function _winAuction(
        Listing storage _tempListing,
        Bid storage _winningBid
    ) private {
        require(_tempListing.isActive, "Listing must be active.");

        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(
            _tempListing.lockID
        );
        require(_pinkLock.token != address(0), "Mismatch in inputs");

        require(address(this).balance >= _winningBid.ethBid, "Insufficient");
        uint256 feeAmount = _winningBid.ethBid / ethFee;
        uint256 toPay = _winningBid.ethBid - feeAmount;
        _winningBid.ethBid = 0;

        if (_tempListing.referral != zeroAddress) {
            uint256 feeForReferral = (feeAmount * referralBonus) / ethFee;
            feeAmount = feeAmount - feeForReferral;
            _tempListing.referral.transfer(feeForReferral);
            feeWallet.transfer(feeAmount);
        } else {
            feeWallet.transfer(feeAmount);
        }

        payable(_tempListing.seller).transfer(toPay);
        _tempListing.isActive = false;
        _tempListing.isSold = true;
        activeListings--;

        pinkLockV2.transferLockOwnership(
            _tempListing.lockID,
            payable(_winningBid.bidder)
        );

        emit BidAccepted(
            _tempListing.lpAddress,
            _tempListing.lockID,
            toPay,
            feeAmount
        );
    }

    /// @notice Redact your bid on select lock - must be done prior to the expiry date of auction.
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    function redactBid(
        address _lpAddress,
        uint256 _lockId
    ) external nonReentrant {
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        require(tempListing.forAuction, "No auction for this listing");

        AuctionDetails memory currentAuction = auctions[
            tempListing.auctionIndex
        ];

        require(currentAuction.topEthBid.ethBid > 0, "No ETH bid present");

        _returnBid(_lpAddress, _lockId, tempListing, msg.sender);
    }

    function _returnBid(
        address _lpAddress,
        uint256 _lockId,
        Listing memory _tempListing,
        address _sender
    ) internal {
        AuctionDetails storage currentAuction = auctions[
            _tempListing.auctionIndex
        ];
        require(
            currentAuction.topEthBid.bidder == _sender,
            "You are not the top ETH bidder"
        );
        address payable toSend = payable(currentAuction.topEthBid.bidder);
        uint256 amount = currentAuction.topEthBid.ethBid;
        currentAuction.topEthBid = Bid(address(0), 0, _tempListing.listingID);

        if (amount > 0) {
            toSend.transfer(amount);

            emit BidRedacted(_sender, _lpAddress, _lockId, amount);
        }
    }

    /// @notice Activate an initiated listing
    /// @dev The seller must have transfered lock ownership to address(this)
    /// @param _lpAddress Address of the LP token
    /// @param _lockId Unique lockID (per lpAddress) of the lock
    function activateListing(address _lpAddress, uint256 _lockId) external {
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        require(tempListing.seller == msg.sender, "Lock doesnt belong to you.");
        require(!tempListing.isActive, "Listing already active.");
        require(!tempListing.isSold, "Listing already sold.");
        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(_lockId);
        address owner = _pinkLock.owner;

        require(owner == address(this), "Lock ownership not yet transferred.");
        lpToLockID[_lpAddress][_lockId].isActive = true;
        activeListings++;
        delete lpBids[_lpAddress][_lockId];
        emit NewActiveListing(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInETH
        );
    }

    function fetchListing(
        address _lpAddress,
        uint256 _lockID
    ) external view returns (Listing memory) {
        return (lpToLockID[_lpAddress][_lockID]);
    }

    function totalUserBidsCount(address _user) external view returns (uint256) {
        return userBids[_user].length;
    }

    function totalLPBidsCount(
        address _lpAddress,
        uint256 _lockID
    ) public view returns (uint256) {
        return lpBids[_lpAddress][_lockID].length;
    }

    function fetchLPBids(
        address _lpAddress,
        uint256 _lockID
    ) external view returns (Bid[] memory) {
        return (lpBids[_lpAddress][_lockID]);
    }

    function fetchAuctionDetails(
        uint256 _auctionIndex
    ) external view returns (AuctionDetails memory) {
        return (auctions[_auctionIndex]);
    }

    /// @notice Purchase a listed LP token lock with ETH
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    function buyLockWithETH(
        address _lpAddress,
        uint256 _lockId
    ) external payable nonReentrant {
        Listing memory _tempListing = lpToLockID[_lpAddress][_lockId];
        require(_tempListing.isActive, "Listing must be active.");
        require(_tempListing.priceInETH > 0, "Listing not for sale in ETH.");
        require(
            msg.value == _tempListing.priceInETH,
            "Incorrect amount of ETH."
        );

        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(_lockId);
        require(_pinkLock.token != address(0), "Mismatch in inputs");

        uint256 feeAmount = msg.value / ethFee;
        uint256 toPay = msg.value - feeAmount;

        if (_tempListing.referral != zeroAddress) {
            uint256 feeForReferral = (feeAmount * referralBonus) / ethFee;
            feeAmount = feeAmount - feeForReferral;
            _tempListing.referral.transfer(feeForReferral);
            feeWallet.transfer(feeAmount);
        } else {
            feeWallet.transfer(feeAmount);
        }

        payable(_tempListing.seller).transfer(toPay);

        if (_tempListing.forAuction) {
            AuctionDetails memory currentAuction = auctions[
                _tempListing.auctionIndex
            ];

            if (currentAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    _tempListing,
                    currentAuction.topEthBid.bidder
                );
            }
        }

        lpToLockID[_lpAddress][_lockId].isActive = false;
        lpToLockID[_lpAddress][_lockId].isSold = true;
        activeListings--;

        pinkLockV2.transferLockOwnership(_lockId, payable(msg.sender));

        emit LockPurchasedWithETH(
            _tempListing.lpAddress,
            _tempListing.lockID,
            toPay,
            feeAmount
        );
    }

    /// @notice Withdraw a listed LP token lock
    /// @dev Only the seller can withdraw the listing
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    function withdrawListing(
        address _lpAddress,
        uint256 _lockId
    ) external nonReentrant {
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );

        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(_lockId);
        address owner = _pinkLock.owner;
        require(owner == address(this), "Marketplace does not own your lock");
        require(_pinkLock.token != address(0), "Mismatch in inputs");

        AuctionDetails memory currentAuction = auctions[
            tempListing.auctionIndex
        ];
        if (tempListing.forAuction && currentAuction.topEthBid.ethBid > 0) {
            _returnBid(
                _lpAddress,
                _lockId,
                tempListing,
                currentAuction.topEthBid.bidder
            );
        }

        if (tempListing.isActive) {
            lpToLockID[_lpAddress][_lockId].isActive = false;
            activeListings--;
        }

        pinkLockV2.transferLockOwnership(_lockId, payable(msg.sender));

        emit ListingWithdrawn(_lpAddress, _lockId);
    }

    /// @notice Verify a listing as safe
    /// @dev Only dev can verify listings
    /// @param _lpAddress Address of the LP token
    /// @param _lockID Unique lock ID (per lpAdress) of the lock
    /// @param status Status of verification
    function verifyListing(
        address _lpAddress,
        uint256 _lockID,
        bool status
    ) external onlyOwner {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockID];
        require(status != tempListing.isVerified, "Must change listing status");
        tempListing.isVerified = true;
        emit LockVerified(_lpAddress, _lockID, status);
    }

    /// @notice Change the ETH price of a listing
    /// @dev Only seller can change price
    /// @param _lpAddress Address of the LP token
    /// @param _lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInETH Updated ETH price of listing
    function changePriceInETH(
        address _lpAddress,
        uint256 _lockID,
        uint256 newPriceInETH
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        tempListing.priceInETH = newPriceInETH;
    }

    /// @notice Return ownership of a lock to the original seller and remove the listing
    /// @dev Only the contract owner can call this function
    /// @param _lpAddress Address of the LP token associated with the lock
    /// @param _lockId The ID of the lock to be redacted
    function redactListing(
        address _lpAddress,
        uint256 _lockId
    ) external onlyOwner {
        Listing storage _tempListing = lpToLockID[_lpAddress][_lockId];

        require(_tempListing.seller != address(0), "Listing does not exist.");

        IPinkLock02.Lock memory _pinkLock = pinkLockV2.getLockById(_lockId);
        require(_pinkLock.token != address(0), "Mismatch in inputs");

        AuctionDetails memory currentAuction = auctions[
            _tempListing.auctionIndex
        ];
        if (_tempListing.forAuction && currentAuction.topEthBid.ethBid > 0) {
            _returnBid(
                _lpAddress,
                _lockId,
                _tempListing,
                currentAuction.topEthBid.bidder
            );
        }

        pinkLockV2.transferLockOwnership(_lockId, _tempListing.seller);

        if (_tempListing.isActive) {
            _tempListing.isActive = false;
            activeListings--;
        }

        delete lpToLockID[_lpAddress][_lockId];
        emit ListingRedacted(_lpAddress, _lockId, _tempListing.seller);
    }
}
