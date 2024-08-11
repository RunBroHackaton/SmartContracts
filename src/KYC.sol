// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";

contract KYC {
    RBGovernor rbgovernor;
    mapping(address => bytes32) public descriptionHash;
    constructor(address payable _rbgovernor) {
        rbgovernor = RBGovernor(_rbgovernor);
    }

    // Propose
    function proposeRegistrationEligibility(address _account, string memory description) public {
        descriptionHash[_account] = keccak256(abi.encodePacked(description));
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("proposeRegistrationEligibility(address,string)", _account, description));
        require(ok);
    }

    // Vote
    function castVote(uint256 _proposalId, uint8 _voteway, string memory _reason ) public {
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("castVoteWithReason(uint256,uint8,string)", _proposalId, _voteway, _reason));
        require(ok);
    }

    // Queue
    function queueData(address target) public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        targets[0] = target;
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("queue(address[],uint256[],bytes[],bytes32)", targets, values, calldatas, descriptionHash[target]));
        require(ok);
    }
    // Execute
    function executeProposal(address target) public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        targets[0] = target;
        (bool ok, ) = address(rbgovernor).delegatecall(abi.encodeWithSignature("execute(address[],uint256[],bytes[],bytes32)", targets, values, calldatas, descriptionHash[target]));
        require(ok);
    }
}