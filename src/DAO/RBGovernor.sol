// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

contract RBGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    struct RewardProposal {
        address target;
        bool approved;
    }

    mapping(uint256 => RewardProposal) public rewardProposals;
    uint256 public nextRewardProposalId;

    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor")
        GovernorSettings(1, /* 1 block */ 50400, /* 1 week */ 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // New functionality for reward eligibility proposals

    function proposeRewardEligibility(address target, string memory description) public returns (uint256) {
        uint256 proposalId = nextRewardProposalId++;
        rewardProposals[proposalId] = RewardProposal({target: target, approved: false});

        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);

        super.propose(targets, values, calldatas, description);
        return proposalId;
    }

    function castVote(uint256 proposalId, uint8 support) public override(Governor) returns (uint256) {
        return super.castVote(proposalId, support);
    }

    function castVoteWithReason(uint256 proposalId, uint8 support, string memory reason) public override(Governor) returns (uint256) {
        return super.castVoteWithReason(proposalId, support, reason);
    }

    function hasProposalPassed(uint256 proposalId) public view returns (bool) {
        ProposalState proposalState = state(proposalId);
        return proposalState == ProposalState.Succeeded;
    }

    function _execute(uint256 proposalId) internal override(Governor, GovernorTimelockControl) {
        RewardProposal storage proposal = rewardProposals[proposalId];
        if (super.state(proposalId) == ProposalState.Succeeded) {
            proposal.approved = true;
        }
        super._execute(proposalId, new address , new uint256 , new bytes , bytes32(0));
    }

    function isEligibleForReward(address target) public view returns (bool) {
        for (uint256 i = 0; i < nextRewardProposalId; i++) {
            if (rewardProposals[i].target == target && rewardProposals[i].approved) {
                return true;
            }
        }
        return false;
    }
}
