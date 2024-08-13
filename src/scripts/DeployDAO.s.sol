// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";
import {Lock} from "dao-submodule/src/Lock.sol";
import {KYC} from "../KYC.sol";

contract DeployGovernance is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4%
    uint256 public constant VOTING_PERIOD = 50400; // Voting period
    uint256 public constant VOTING_DELAY = 1; // Voting delay

    address[] proposers;
    address[] executors;

    RunBroToken public rbToken; 
    address public rbTokenAddress = 0xC01Bfb7A1Aa01eA3b3BB84f8d6dCE8Bda79dB468;

    function run() external {
        vm.startBroadcast();

        Lock timelock = new Lock(MIN_DELAY, proposers, executors);
        RBGovernor governor = new RBGovernor(rbToken, timelock);
        KYC kyc = new KYC(payable(address(governor)));

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();


        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, msg.sender);
        vm.stopBroadcast();

        console.log("Lock Address", address(timelock));
        console.log("Governor Address", address(governor));
        console.log("KYC Address", address(kyc));
    }
}
