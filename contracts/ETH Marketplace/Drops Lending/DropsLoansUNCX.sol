pragma solidity ^0.8.0;
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

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

contract DropsLoansUnicrypt is Ownable, ReentrancyGuard {
    IERC20 public dropsToken;
    uint256 public totalLoans;
    uint256 public maxDailyInterest;
    uint256 public maxLateInterest;
    uint256 public minLength;
    uint256 public maxLength;
    uint256 public timeToDefault;

    mapping(address => mapping(address => Loan)) userLoan;
    mapping(address => mapping(address => Request)) userRequest;

    event RequestSubmitted(
        address payable lender,
        address lpAddress,
        uint256 lockId,
        uint256 length);

    event LoanApproved(
        address payable lender,
        address lpAddress,
        uint256 lockId,
        uint256 length,
        uint256 dailyInterest,
        uint256 lateInterest
    );

    event LoanTaken(
        address payable lender,
        address lpAddress,
        uint256 lockId,
        uint256 length,
        uint256 dailyInterest,
        uint256 lateInterest
    );

    struct Loan {
        address payable lender;
        uint256 dailyInterest;
        uint256 lateInterest;
        uint256 amountOfEth;
        address lpAddress;
        uint256 lockId;
        uint256 startTime;
        uint256 length;
        bool commenced;
    }

    struct Request {
        address payable lender;
        address lpAddress;
        int lockId;
        uint256 length;
        bool accepted;
    }

    function requestLoan(
        address _lpAddresss, 
        uint256 _lockId,
        uint256 _length) external nonReentrant {

        require(userLoan[msg.sender][_lpAddress].lender == address(0), "You already have a loan");
        (, , , , , address owner) = uniswapV2Locker.tokenLocks(
            _lpAddress,
            _lockId
        );
        require(msg.sender == owner, "You dont own this lock");
        require(_length > minLength, "Length too short");
        require(_length < maxLength, "Length too long");

        userRequest[msg.sender][_lpAddress] = Request(
            msg.sender,
            _lpAddress,
            _lockId,
            _length,
            false
        );

        emit RequestSubmitted(msg.sender, _lpAddress, _lockId, _length);
    }

    function approveLoan(
        address _lender, 
        uint256 _dailyInterest, 
        uint256 _lateInterest, 
        uint256 _amountOfEth) external onlyOwner {

        Request storage tempRequest = Request[msg.sender];
        require(!tempRequest.accepted, "Request already accepted");
        require(_dailyInterest < maxDailyInterest && _lateInterest < maxLateInterest, "Interest rates too high");


        userLoan[_lender][tempRequest.lpAddress] = Loan(
            _lender, 
            _dailyInterest, 
            _lateInterest, 
            _amountOfEth, 
            tempRequest.lpAddress,
            tempRequest.lockId,
            0,
            tempRequest.length,
            false);

        tempRequest.accepted = true;

        emit LoanApproved(
            _lender, 
            tempRequest.lpAddress, 
            tempRequest.lockId, 
            tempRequest.length, 
            _dailyInterest, 
            _lateInterest);
    }

    function takeLoan(address _lpAddress) external payable {
        require(userLoan[msg.sender].lender == msg.sender, "Loan unapproved");
        Loan storage tempLoan = userLoan[msg.sender];
        Request memory tempRequest = userRequest[msg.sender][_lpAddress];
        require(msg.value == tempLoan.amountOfEth);
        require(tempRequest.accepted, "Loan unapproved");
        require(!tempLoan.commenced, "Loan already taken");
        (bool status, uint256 index) = _getIndexForUserLock(tempLoan.lpAddress, tempLoan.lockId, address(this));
        require(status, "Lock ownership must be transfered to this contract");

        tempLoan.startTime = block.timestamp;
        tempLoan.lender.transfer(tempLoan.amountOfEth);

        emit LoanTaken(
            msg.sender, 
            tempLoan.lpAddress, 
            tempLoan.lockId, 
            tempLoan.length, 
            tempLoan.dailyInterest, 
            tempLoan.lateInterest);
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

    function calculateInterest(address _lpAddress) public view returns (uint256) {
        Loan storage loan = userLoan[msg.sender][_lpAddress];
        require(loan.commenced, "Loan has not commenced");

        uint256 currentTime = block.timestamp;
        uint256 totalInterest = 0;
        uint256 duration = loan.length;
        uint256 dailyInterest = loan.dailyInterest;
        uint256 lateInterest = loan.lateInterest;
        uint256 amountOfEth = loan.amountOfEth;

        if (currentTime <= loan.startTime + duration * 1 days) {
            uint256 daysElapsed = (currentTime - loan.startTime) / 1 days;
            totalInterest = compoundInterest(amountOfEth, dailyInterest, daysElapsed);
        } else {
            uint256 daysBeforeLate = duration;
            uint256 daysAfterLate = (currentTime - (loan.startTime + duration * 1 days)) / 1 days;
            uint256 interestBeforeLate = compoundInterest(amountOfEth, dailyInterest, daysBeforeLate);
            totalInterest = interestBeforeLate + compoundInterest(interestBeforeLate, lateInterest, daysAfterLate);
        }

        return totalInterest;
    }

    function compoundInterest(uint256 principal, uint256 rate, uint256 time) internal pure returns (uint256) {
        for (uint256 i = 0; i < time; i++) {
            principal += (principal * rate) / 10000;
        }
        return principal;
    }

    function repayLoan(address _lpAddress) external payable nonReentrant {
        Loan storage loan = userLoan[msg.sender][_lpAddress];
        require(loan.commenced, "Loan has not commenced");

        uint256 currentDebt = calculateInterest(_lpAddress);
        uint256 totalDebt = loan.amountOfEth + currentDebt - loan.repaidAmount;
        require(msg.value <= totalDebt, "Repayment exceeds total debt");

        loan.repaidAmount += msg.value;

        if (loan.repaidAmount >= totalDebt) {
            (bool status, uint256 index) = _getIndexForUserLock(loan.lpAddress, loan.lockId, address(this));
            require(status, "Lock ownership transfer failed");
            uniswapV2Locker.transferLockOwnership(loan.lpAddress, index, loan.lockId, payable(msg.sender));
        }

        emit LoanRepaid(msg.sender, loan.lpAddress, loan.lockId, msg.value, totalDebt - loan.repaidAmount);
    }


}