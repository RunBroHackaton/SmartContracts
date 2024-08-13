// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";

contract KYC {
    RBGovernor rbgovernor;
    // mapping(address => bytes32) public descriptionHash;

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string description;
    constructor(address payable _rbgovernor) {
        rbgovernor = RBGovernor(_rbgovernor);
    }

    function addTargetAccount(address _account) public {
        targets.push(_account);
    }
    // Propose
    function propose() public {
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("propose(address[],uint256[],bytes[],string)", targets, values, calldatas, description));
        require(ok);
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
}