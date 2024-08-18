// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";
import {Lock} from "dao-submodule/src/Lock.sol";
import {KYC} from "../KYC.sol";
import {AccountRegistry} from "../AccountRegistry.sol";

contract DeployGovernance is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4%
    uint256 public constant VOTING_PERIOD = 50400; // Voting period
    uint256 public constant VOTING_DELAY = 1; // Voting delay

    address[] proposers;
    address[] executors;

    RunBroToken public rbToken; 
    address public rbTokenAddress = 0xd6A94Ba53942E585dF9a42b4B8b573491302a9e1;
    function run() external {
        vm.startBroadcast();

        proposers.push(0x345F30Cea2EF88227C2D301302E17900E1FcDA06);
        proposers.push(0xd2fdd21AC3553Ac578a69a64F833788f2581BF05);

        executors.push(0x345F30Cea2EF88227C2D301302E17900E1FcDA06);
        executors.push(0xd2fdd21AC3553Ac578a69a64F833788f2581BF05);

        Lock timelock = new Lock(MIN_DELAY, proposers, executors);
        RBGovernor governor = new RBGovernor(rbToken, timelock);

        AccountRegistry ar = new AccountRegistry();
        KYC kyc = new KYC(payable(address(governor)), address(ar));
        

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
        console.log("AccountRegistry Address", address(ar));
    }
}
