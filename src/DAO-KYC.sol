// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RunBroToken} from "./RunBroToken.sol";

contract KYC {
    struct Proposal {
        address proposer;
        address user;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        bool exists;
    }

    uint256 public sellerCount;
    uint256 public proposal_counter;

    mapping(address => string) public sellerDetails;
    mapping(address => uint256) public proposalIdOfSeller;
    
    address[] public proposedAddressArray;
    address[] public abc;

    //-----------------------------------------------------------
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public votingPeriod = 5 minutes;

    mapping(address => bool) public addUserToPlatform;

    RunBroToken public rbToken;

    modifier onlyMember() {
        require(members[msg.sender], "Not a DAO member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].exists, "Proposal does not exist");
        _;
    }

    constructor(address _rbToken) {
        members[msg.sender] = true;
        rbToken = RunBroToken(_rbToken);
    }

    function addDetails(string memory tiktokurl) public {
        sellerDetails[msg.sender] = tiktokurl;
        addTargetAccount(msg.sender);
    }

    function addTargetAccount(address _account) internal {
        abc.push(_account);
        sellerCount++;
    }

// 0xd2fdd21AC3553Ac578a69a64F833788f2581BF05

    function addMember(address _member) public onlyMember {
        members[_member] = true;
    }

    function proposeUser() public onlyMember returns (uint256) {
        require(proposalCount<=sellerCount,"wrong-arg");
        address currentUser = abc[proposalCount];
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            user: currentUser,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingPeriod,
            executed: false,
            exists: true
        });
        proposalIdOfSeller[currentUser] = proposalCount;
        proposedAddressArray.push(currentUser);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) public onlyMember proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
    }

    function queueProposal(uint256 proposalId) public onlyMember proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        proposal.executed = true;
    }

    function executeProposal(uint256 proposalId) public onlyMember proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.executed, "Proposal not queued for execution");
        
        _registerUser(proposal.user);
    }

    function _registerUser(address _user) internal {
        addUserToPlatform[_user] = true;
    }

    //--------------------------------VIEW FUNCTIONS------------------------------------------------
    //----------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------

    function checkAmountOfRBT_UserHolds(address _account) public view returns(uint256){
        return rbToken.balanceOf(_account);
    }
    function checkIfSellerIsRegisteredOrNot(address _account) public view returns(bool){
        return addUserToPlatform[_account];
    }
    function getAllTheElementsInTargetArray() public view returns(address[] memory){
        return abc;
    }
    function getsellersDetails(address _account) public view returns(string memory) {
        return sellerDetails[_account];
    }

    function getProposalIdOfSeller(address _account) public view returns(uint256){
        return proposalIdOfSeller[_account];
    }

    function getAllProposedAccounts() public view returns(address[] memory){
        return proposedAddressArray;
    }

    function getVotingStatus(uint256 proposalId) public view proposalExists(proposalId) returns (
        uint256 votesFor,
        uint256 votesAgainst,
        bool isActive
    ) {
        Proposal storage proposal = proposals[proposalId];
        votesFor = proposal.votesFor;
        votesAgainst = proposal.votesAgainst;
        isActive = block.timestamp < proposal.deadline;
    }
}
