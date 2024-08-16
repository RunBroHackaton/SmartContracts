// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";
import {IGovernor} from "openzeppelin-contracts/contracts/governance/IGovernor.sol";

contract KYC {
    RBGovernor rbgovernor;
    // mapping(address => bytes32) public descriptionHash;

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string description;

    uint256 public seller_counter;
    uint256 public proposal_counter;

    mapping(address => string) public sellerDetails;
    mapping(address => uint256) public proposalIdOfSeller;

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
    constructor(address payable _rbgovernor) {
        rbgovernor = RBGovernor(_rbgovernor);
    }

    function addDetails(string memory tiktokurl) public {
        sellerDetails[msg.sender] = tiktokurl;
        addTargetAccount(msg.sender);
    }

    function addTargetAccount(address _account) internal {
        targets.push(_account);
        seller_counter++;
    }

    function myFunction() public pure returns (uint[] memory) {
        uint[] memory myArray = new uint[](1);
        myArray[0] = 42; // Assign a value to the single element
        return myArray;
    }
    // Propose
    function propose() public returns(uint256 proposalId){
        require(proposal_counter<=seller_counter,"wrong-arg");
        address[] memory myArray = new address[](1);
        myArray[0] = targets[proposal_counter];

        (bool ok, bytes memory returnData) = address(rbgovernor).delegatecall(
            abi.encodeWithSignature("propose(address[],uint256[],bytes[],string)", myArray, values, calldatas, description)
        );
        require(ok, "Delegatecall to propose failed");
        proposal_counter++;
        proposalId = abi.decode(returnData, (uint256));
        proposalIdOfSeller[myArray[0]] = proposalId;
    }
    // Propose
    function proposeRegistrationEligibility(address _account) public {
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("proposeRegistrationEligibility(address,string)", _account, description));
        require(ok);
    }

    // Vote
    function castVote(uint256 _proposalId, uint8 _voteway, string memory _reason ) public {
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("castVoteWithReason(uint256,uint8,string)", _proposalId, _voteway, _reason));
        require(ok);
    }

    // Queue
    function queueData() public {
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("queue(address[],uint256[],bytes[],bytes32)", targets, values, calldatas, descriptionHash));
        require(ok);
    }
    // Execute
    function executeProposal() public {
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("execute(address[],uint256[],bytes[],bytes32)", targets, values, calldatas, descriptionHash));
        require(ok);
    }

    function checkVotingStatus(uint256 proposalId) public view returns(IGovernor.ProposalState) {
        return rbgovernor.state(proposalId);
    }

    function registrationElgibility(address _account) public view returns(bool){
        return rbgovernor.isEligibleForRegistration(_account);
    }

    //--------------------------------VIEW FUNCTIONS------------------------------------------------
    //----------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------
    function getsellersDetails(address _account) public view returns(string memory) {
        return sellerDetails[_account];
    }

    function getProposalIdOfSeller(address _account) public view returns(uint256){
        return proposalIdOfSeller[_account];
    }
}