// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IDropsTier {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 noWithdrawalFeeAfter;
        uint256 depositTime;
        uint256 rewardLockedUp;
    }

    function userInfo(address user) external view returns (UserInfo memory);
}

contract DROPSDAO {
    using SafeERC20 for IERC20;

    IERC20 public dropsToken;
    IDropsTier public dropsTier02;
    IDropsTier public dropsTier03;
    uint256 public constant MIN_PROPOSAL_AMOUNT = 150000 * 10 ** 18;
    uint256 public constant VOTING_QUORUM_PERCENTAGE = 15;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public totalSupply;

    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 id, bool passed);

    constructor(IERC20 _dropsToken, IDropsTier _dropsTier02, IDropsTier _dropsTier03) {
        dropsToken = _dropsToken;
        dropsTier02 = _dropsTier02;
        dropsTier03 = _dropsTier03;
        totalSupply = dropsToken.totalSupply();
    }

    function createProposal(string memory description) external {
        require(dropsToken.balanceOf(msg.sender) >= MIN_PROPOSAL_AMOUNT, "Insufficient balance to create proposal");

        dropsToken.transferFrom(msg.sender, address(this), MIN_PROPOSAL_AMOUNT);

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        proposalCount++;

        emit ProposalCreated(proposalCount - 1, msg.sender, description);
    }

    function vote(uint256 proposalId, bool voteYes) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 voterBalance = getVotingPower(msg.sender);
        require(voterBalance > 0, "Must hold tokens to vote");

        if (voteYes) {
            proposal.yesVotes += voterBalance;
        } else {
            proposal.noVotes += voterBalance;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, voteYes);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes >= (totalSupply * VOTING_QUORUM_PERCENTAGE) / 100, "Not enough votes");

        bool passed = proposal.yesVotes > proposal.noVotes;

        proposal.executed = true;

        dropsToken.transfer(proposal.proposer, MIN_PROPOSAL_AMOUNT);

        emit ProposalExecuted(proposalId, passed);
    }

    function getVotingPower(address user) public view returns (uint256) {
        uint256 dropsBalance = dropsToken.balanceOf(user);
        uint256 dropsTier02Balance = dropsTier02.userInfo(user).amount;
        uint256 dropsTier03Balance = dropsTier03.userInfo(user).amount;

        return dropsBalance + dropsTier02Balance + dropsTier03Balance;
    }
}
