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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IUniswapV2Locker {
    // Getter function to fetch details about a specific lock for a user
    function getUserLockForTokenAtIndex(
        address user,
        address lpAddress,
        uint256 index
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address);

    function tokenLocks(
        address lpAddress,
        uint256 lockID
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address);

    // Function to transfer the ownership of a lock
    function transferLockOwnership(
        address lpAddress,
        uint256 index,
        uint256 lockID,
        address payable newOwner
    ) external;

    function getUserNumLocksForToken(
        address _user,
        address _lpAddress
    ) external view returns (uint256);
}

/// @title Marketplace for LP Token Lock Ownership
/// @notice This contract allows users to list and sell their Uniswap V2 LP token lock ownerships locked through Unicrypt.
contract DropsUnicryptMarketplace is Ownable, ReentrancyGuard {
    // Unicrypt V2 Locker address
    IUniswapV2Locker public uniswapV2Locker;

    // Native Drops token address
    IERC20 public dropsToken;
    address payable public feeWallet;
    uint256 public listingCount;
    address public marketplaceOwner;
    uint256 public activeListings;
    uint256 public listedLPsCount;
    uint256 public totalValueListedInDrops;
    uint256 public totalValueList;
    uint256 public ethFee;
    uint256 public referralBonus;

    // Zero address constant
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    // Relevant listing info
    struct Listing {
        uint256 lockID;
        uint256 listingID;
        uint256 listingIndex;
        address payable seller;
        address lpAddress;
        uint256 priceInETH;
        uint256 priceInDrops;
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
        uint256 dropsBid;
        uint256 ethBid;
        uint256 listingID;
    }

    struct ListingDetail {
        uint256 lockID;
        address lpAddress;
    }

    struct AuctionDetails {
        Bid topEthBid;
        Bid topDropsBid;
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
        uint256 bidInDrops,
        uint256 bidInEth
    );
    event BidRedacted(
        address bidder,
        address lpAddress,
        uint256 lockId,
        uint256 bidInDrops,
        uint bidInEth
    );
    event BidAccepted(
        address lpToken,
        uint256 lockId,
        uint256 profitInEth,
        uint256 feeEth,
        uint256 profitInDrops
    );
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
    /// @param _uniswapV2Locker Address of the Uniswap V2 Locker contract
    /// @param _feeWallet Address of the wallet where fees will be collected
    /// @param _dropsTokenAddress Address of the Drops token contract
    constructor(
        address _uniswapV2Locker,
        address payable _feeWallet,
        address _dropsTokenAddress
    ) Ownable(msg.sender) {
        uniswapV2Locker = IUniswapV2Locker(_uniswapV2Locker);
        feeWallet = _feeWallet;
        marketplaceOwner = msg.sender;
        dropsToken = IERC20(_dropsTokenAddress);
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
    /// @param _uniswapV2Locker The address of the new liquidity locker
    function setLockerAddress(address _uniswapV2Locker) external onlyOwner {
        require(
            address(uniswapV2Locker) != _uniswapV2Locker,
            "Must input different contract address"
        );
        require(
            _uniswapV2Locker != zeroAddress,
            "Cant set locker address as zero address"
        );
        uniswapV2Locker = IUniswapV2Locker(_uniswapV2Locker);
        emit LockerAddressUpdated(_uniswapV2Locker);
    }

    function _initializeAuctionDetails(
        uint256 _listingId
    ) internal pure returns (AuctionDetails memory) {
        AuctionDetails memory blankAuctionDetails;
        blankAuctionDetails.topEthBid = Bid(address(0), 0, 0, _listingId);
        blankAuctionDetails.topDropsBid = Bid(address(0), 0, 0, _listingId);

        return blankAuctionDetails;
    }

    /// @notice List an LP token lock for sale
    /// @dev The seller must be the owner of the lock and approve this contract to manage the lock
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    /// @param _priceInETH The selling price in ETH
    /// @param _priceInDrops The selling price in Drops tokens
    function initiateListing(
        address _lpAddress,
        uint256 _lockId,
        uint256 _priceInETH,
        uint256 _priceInDrops,
        address payable _referral
    ) external {
        (, , , , , address owner) = uniswapV2Locker.tokenLocks(
            _lpAddress,
            _lockId
        );
        require(msg.sender == owner, "You dont own that lock.");
        require(
            (_priceInETH > 0) || (_priceInDrops > 0),
            "You must set a price in Drops or ETH"
        );
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        (bool lockFound, uint256 index) = _getIndexForUserLock(
            _lpAddress,
            _lockId,
            _msgSender()
        );
        require(lockFound, "Lock not found!");
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
            index,
            payable(msg.sender),
            _lpAddress,
            _priceInETH,
            _priceInDrops,
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
            0,
            msg.value,
            tempListing.listingID
        );

        userBids[msg.sender].push(currentAuction.topEthBid);
        lpBids[_lpAddress][_lockId].push(currentAuction.topEthBid);
        emit NewBid(msg.sender, _lpAddress, _lockId, 0, msg.value);
    }

    /// @notice Bid on a listing with Drops - transfer Drops to CA until bid is either beat, accepted, or withdrawn
    /// @dev Bidder must not be listing owner
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    /// @param _amount Amount of Drops to bid with
    function bidDrops(
        address _lpAddress,
        uint256 _lockId,
        uint256 _amount
    ) external nonReentrant {
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
            _amount > currentAuction.topDropsBid.dropsBid,
            "Must outbid current highest bid"
        );

        if (currentAuction.topDropsBid.dropsBid > 0) {
            dropsToken.transfer(
                currentAuction.topDropsBid.bidder,
                currentAuction.topDropsBid.dropsBid
            );
        }

        dropsToken.transferFrom(msg.sender, address(this), _amount);

        currentAuction.topDropsBid = Bid(
            msg.sender,
            _amount,
            0,
            tempListing.listingID
        );

        userBids[msg.sender].push(currentAuction.topDropsBid);
        lpBids[_lpAddress][_lockId].push(currentAuction.topDropsBid);

        emit NewBid(msg.sender, _lpAddress, _lockId, _amount, 0);
    }

    function acceptBid(
        address _lpAddress,
        uint256 _lockId,
        bool _eth
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockId];
        AuctionDetails storage tempAuction = auctions[tempListing.auctionIndex];
        require(tempListing.seller == msg.sender, "Owner can accept bid");

        Bid storage topBid;
        if (_eth) {
            topBid = tempAuction.topEthBid;
            if (tempAuction.topDropsBid.dropsBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    !_eth,
                    tempListing,
                    tempAuction.topDropsBid.bidder
                );
            }
        } else {
            topBid = tempAuction.topDropsBid;
            if (tempAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    _eth,
                    tempListing,
                    tempAuction.topEthBid.bidder
                );
            }
        }

        require(
            (topBid.ethBid > 0 && _eth) || (topBid.dropsBid > 0 && !_eth),
            "Bid must exceed 0"
        );

        _winAuction(tempListing, topBid, _eth);
    }

    function _winAuction(
        Listing storage _tempListing,
        Bid storage _winningBid,
        bool _eth
    ) private {
        require(_tempListing.isActive, "Listing must be active.");
        (bool lockFound, uint256 index) = _getIndex(
            _tempListing.lpAddress,
            _tempListing
        );
        require(lockFound, "Mismatch in inputs");

        if (_eth) {
            require(
                address(this).balance >= _winningBid.ethBid,
                "Insufficient"
            );
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

            uniswapV2Locker.transferLockOwnership(
                _tempListing.lpAddress,
                index,
                _tempListing.lockID,
                payable(_winningBid.bidder)
            );

            emit BidAccepted(
                _tempListing.lpAddress,
                _tempListing.lockID,
                toPay,
                feeAmount,
                0
            );
        } else {
            require(
                dropsToken.balanceOf(address(this)) > _winningBid.dropsBid,
                "Insufficient drops."
            );

            uint256 toSend = _winningBid.dropsBid;
            require(dropsToken.transfer(_tempListing.seller, toSend));
            _winningBid.dropsBid = 0;

            _tempListing.isActive = false;
            _tempListing.isSold = true;
            activeListings--;

            uniswapV2Locker.transferLockOwnership(
                _tempListing.lpAddress,
                index,
                _tempListing.lockID,
                payable(_winningBid.bidder)
            );

            emit BidAccepted(
                _tempListing.lpAddress,
                _tempListing.lockID,
                0,
                0,
                toSend
            );
        }
    }

    /// @notice Redact your bid on select lock - must be done prior to the expiry date of auction.
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    /// @param _eth True if bidder is redacting a bid in ETH, false if bid is in Drops
    function redactBid(
        address _lpAddress,
        uint256 _lockId,
        bool _eth
    ) external nonReentrant {
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        require(tempListing.forAuction, "No auction for this listing");

        AuctionDetails memory currentAuction = auctions[
            tempListing.auctionIndex
        ];

        if (_eth) {
            require(currentAuction.topEthBid.ethBid > 0, "No ETH bid present");
        } else {
            require(
                currentAuction.topDropsBid.dropsBid > 0,
                "No Drops bid present"
            );
        }

        _returnBid(_lpAddress, _lockId, _eth, tempListing, msg.sender);
    }

    function _returnBid(
        address _lpAddress,
        uint256 _lockId,
        bool _eth,
        Listing memory _tempListing,
        address _sender
    ) internal {
        AuctionDetails storage currentAuction = auctions[
            _tempListing.auctionIndex
        ];
        if (_eth) {
            require(
                currentAuction.topEthBid.bidder == _sender,
                "You are not the current ETH bidder"
            );
            address payable toSend = payable(currentAuction.topEthBid.bidder);
            uint256 amount = currentAuction.topEthBid.ethBid;
            currentAuction.topEthBid = Bid(
                address(0),
                0,
                0,
                _tempListing.listingID
            );

            if (amount > 0) {
                toSend.transfer(amount);

                emit BidRedacted(_sender, _lpAddress, _lockId, 0, amount);
            }
        } else {
            require(
                currentAuction.topDropsBid.bidder == _sender,
                "You are not the top Drops bidder"
            );
            address toSend = currentAuction.topDropsBid.bidder;
            uint256 amount = currentAuction.topDropsBid.dropsBid;
            currentAuction.topDropsBid = Bid(
                address(0),
                0,
                0,
                _tempListing.listingID
            );

            if (amount > 0) {
                dropsToken.transfer(toSend, amount);

                emit BidRedacted(_sender, _lpAddress, _lockId, amount, 0);
            }
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
        (, , , , , address owner) = uniswapV2Locker.tokenLocks(
            _lpAddress,
            _lockId
        );
        require(owner == address(this), "Lock ownership not yet transferred.");
        lpToLockID[_lpAddress][_lockId].isActive = true;
        activeListings++;
        delete lpBids[_lpAddress][_lockId];
        emit NewActiveListing(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInETH,
            tempListing.priceInDrops
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
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];
        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInETH > 0, "Listing not for sale in ETH.");
        require(
            msg.value == tempListing.priceInETH,
            "Incorrect amount of ETH."
        );

        (bool lockFound, uint256 index) = _getIndex(_lpAddress, tempListing);

        require(lockFound, "Mismatch in inputs");

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

        if (tempListing.forAuction) {
            AuctionDetails memory currentAuction = auctions[
                tempListing.auctionIndex
            ];

            if (
                currentAuction.topDropsBid.dropsBid > 0 &&
                currentAuction.topEthBid.ethBid > 0
            ) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );

                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            } else if (currentAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );
            } else if (currentAuction.topDropsBid.dropsBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            }
        }

        lpToLockID[_lpAddress][_lockId].isActive = false;
        lpToLockID[_lpAddress][_lockId].isSold = true;
        activeListings--;

        uniswapV2Locker.transferLockOwnership(
            _lpAddress,
            index,
            _lockId,
            payable(msg.sender)
        );

        emit LockPurchasedWithETH(
            tempListing.lpAddress,
            tempListing.lockID,
            toPay,
            feeAmount
        );
    }

    /// @notice Purchase a listed LP token lock with Drops tokens
    /// @dev Requires approval to transfer Drops tokens to cover the purchase price
    /// @param _lpAddress Address of the LP token
    /// @param _lockId The ID of the lock
    function buyLockWithDrops(
        address _lpAddress,
        uint256 _lockId
    ) external payable nonReentrant {
        Listing memory tempListing = lpToLockID[_lpAddress][_lockId];

        require(tempListing.isActive, "Listing must be active.");
        require(tempListing.priceInDrops > 0, "Listing not for sale in Drops.");
        require(
            dropsToken.balanceOf(msg.sender) > tempListing.priceInDrops,
            "Insufficient drops."
        );

        (bool lockFound, uint256 index) = _getIndex(_lpAddress, tempListing);

        require(lockFound, "Mismatch in inputs.");
        require(
            dropsToken.transferFrom(
                msg.sender,
                tempListing.seller,
                tempListing.priceInDrops
            )
        );

        if (tempListing.forAuction) {
            AuctionDetails memory currentAuction = auctions[
                tempListing.auctionIndex
            ];

            if (
                currentAuction.topDropsBid.dropsBid > 0 &&
                currentAuction.topEthBid.ethBid > 0
            ) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );

                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            } else if (currentAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );
            } else if (currentAuction.topDropsBid.dropsBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            }
        }

        lpToLockID[_lpAddress][_lockId].isActive = false;
        lpToLockID[_lpAddress][_lockId].isSold = true;
        activeListings--;

        uniswapV2Locker.transferLockOwnership(
            _lpAddress,
            index,
            _lockId,
            payable(msg.sender)
        );

        emit LockPurchasedWithDrops(
            tempListing.lpAddress,
            tempListing.lockID,
            tempListing.priceInDrops
        );
    }

    function getIndex(
        address _user,
        address _lpAddress,
        uint256 _lockId
    ) external view returns (bool, uint256) {
        return _getIndexForUserLock(_lpAddress, _lockId, _user);
    }

    /// @notice Find unique (per lpAddress) lock index in order to transfer lock ownership
    /// @param _lpAddress Address of the LP token
    /// @param _listing Listing in question
    function _getIndex(
        address _lpAddress,
        Listing memory _listing
    ) internal view returns (bool, uint256) {
        uint256 index;
        uint256 numLocksAtAddress = uniswapV2Locker.getUserNumLocksForToken(
            address(this),
            _lpAddress
        );
        bool lockFound = false;

        if (numLocksAtAddress == 1) {
            index = 0;
            lockFound = true;
        } else {
            for (index = 0; index < numLocksAtAddress; index++) {
                (, , , , uint256 _lockId, ) = uniswapV2Locker
                    .getUserLockForTokenAtIndex(
                        address(this),
                        _lpAddress,
                        index
                    );
                if (_lockId == _listing.lockID) {
                    lockFound = true;
                    break;
                }
            }
        }
        return (lockFound, index);
    }

    function _getIndexForUserLock(
        address _lpAddress,
        uint256 _lockId,
        address user
    ) internal view returns (bool, uint256) {
        uint256 index;
        uint256 numLocksAtAddress = uniswapV2Locker.getUserNumLocksForToken(
            user,
            _lpAddress
        );
        bool lockFound = false;
        if (numLocksAtAddress == 1) {
            index = 0;
            lockFound = true;
        } else {
            for (index = 0; index < numLocksAtAddress; index++) {
                (, , , , uint256 _tempLockID, ) = uniswapV2Locker
                    .getUserLockForTokenAtIndex(user, _lpAddress, index);
                if (_tempLockID == _lockId) {
                    lockFound = true;
                    break;
                }
            }
        }
        return (lockFound, index);
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

        (, , , , , address owner) = uniswapV2Locker.tokenLocks(
            _lpAddress,
            _lockId
        );
        require(owner == address(this), "Marketplace does not own your lock");

        (bool lockFound, uint256 index) = _getIndex(_lpAddress, tempListing);

        require(lockFound, "Mismatch in inputs.");

        if (tempListing.forAuction) {
            AuctionDetails memory currentAuction = auctions[
                tempListing.auctionIndex
            ];

            if (
                currentAuction.topDropsBid.dropsBid > 0 &&
                currentAuction.topEthBid.ethBid > 0
            ) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );

                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            } else if (currentAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    tempListing,
                    currentAuction.topEthBid.bidder
                );
            } else if (currentAuction.topDropsBid.dropsBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    tempListing,
                    currentAuction.topDropsBid.bidder
                );
            }
        }

        if (tempListing.isActive) {
            lpToLockID[_lpAddress][_lockId].isActive = false;
            activeListings--;
        }

        uniswapV2Locker.transferLockOwnership(
            _lpAddress,
            index,
            _lockId,
            payable(msg.sender)
        );

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

    /// @notice Change the price of a listing in Drops
    /// @dev Only seller can change price
    /// @param _lpAddress Address of the LP token
    /// @param _lockID Unique lock ID (per lpAddress) of the lock
    /// @param newPriceInDrops Updated Drops price of listing
    function changePriceInDrops(
        address _lpAddress,
        uint256 _lockID,
        uint256 newPriceInDrops
    ) external nonReentrant {
        Listing storage tempListing = lpToLockID[_lpAddress][_lockID];
        require(
            tempListing.seller == msg.sender,
            "This listing does not belong to you."
        );
        tempListing.priceInDrops = newPriceInDrops;
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

        (bool lockFound, uint256 index) = _getIndex(_lpAddress, _tempListing);
        require(lockFound, "Lock not found.");

        if (_tempListing.forAuction) {
            AuctionDetails memory currentAuction = auctions[
                _tempListing.auctionIndex
            ];

            if (
                currentAuction.topDropsBid.dropsBid > 0 &&
                currentAuction.topEthBid.ethBid > 0
            ) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    _tempListing,
                    currentAuction.topEthBid.bidder
                );

                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    _tempListing,
                    currentAuction.topDropsBid.bidder
                );
            } else if (currentAuction.topEthBid.ethBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    true,
                    _tempListing,
                    currentAuction.topEthBid.bidder
                );
            } else if (currentAuction.topDropsBid.dropsBid > 0) {
                _returnBid(
                    _lpAddress,
                    _lockId,
                    false,
                    _tempListing,
                    currentAuction.topDropsBid.bidder
                );
            }
        }

        uniswapV2Locker.transferLockOwnership(
            _lpAddress,
            index,
            _lockId,
            _tempListing.seller
        );

        if (_tempListing.isActive) {
            _tempListing.isActive = false;
            activeListings--;
        }

        delete lpToLockID[_lpAddress][_lockId];
        emit ListingRedacted(_lpAddress, _lockId, _tempListing.seller);
    }
}
