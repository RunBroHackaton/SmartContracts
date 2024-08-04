// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
// import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {MarketPlace} from "../Marketplace.sol";
// import {Reward} from "../RewardModels/RewardModel3.sol";
import {GetStepsAPI} from "../GoogleStepsApi.sol";
import {WethRegistry} from "../PoolModels/WethRegistry.sol";
import {WethReward} from "../RewardModels/WethRewardModel.sol";
import {Escrow} from "../Escrow.sol";

// DAO imports
import {RBGovernor} from "dao-submodule/src/RBGovernor.sol";
import {Lock} from "dao-submodule/src/Lock.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address s_owner) external view returns (uint);

    function allowance(
        address s_owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);
}

contract DeployContracts is Script {
    address public constant wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // On Sepolia
    // address public constant wethAddress =
    // 0x52eF3d68BaB452a294342DC3e5f464d7f610f72E; // On Amoy
    uint256 public initialSupply = 1000000 * 10 ** 18;
    uint256 public initial_rbTokens_inPool = 10000 * 10 ** 18;
    uint256 public initial_weth_inPool = 10000 * 10 ** 18;

    address public seller = address(1);
    address public buyer = address(2);

    address public owner;

    // DAOs datas
    address[] proposers;
    address[] executors;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    Lock lock;
    RBGovernor rbgovernor;
    function run() external {
        owner = msg.sender;
        vm.startBroadcast(owner);

        RunBroToken rbToken = new RunBroToken(initialSupply);
        Escrow escrow = new Escrow();

        WethRegistry wethRegistry = new WethRegistry();
        MarketPlace marketPlace = new MarketPlace(address(wethRegistry), wethAddress, payable(address(escrow)), address(rbToken));
        
        GetStepsAPI getstepsapi = new GetStepsAPI(address(wethRegistry));
        WethReward wethReward = new WethReward(wethAddress, address(marketPlace), payable(address(wethRegistry)), address(getstepsapi));

        // DAO deployments
        lock = new Lock(MIN_DELAY, proposers, executors);
        rbgovernor = new RBGovernor(rbToken, lock);

        bytes32 proposerRole = lock.PROPOSER_ROLE();
        bytes32 executorRole = lock.EXECUTOR_ROLE();
        bytes32 adminRole = lock.TIMELOCK_ADMIN_ROLE();

        lock.grantRole(proposerRole, address(rbgovernor));
        lock.grantRole(executorRole, address(0));
        lock.revokeRole(adminRole, msg.sender);

        vm.stopBroadcast();

        console.log("RB Token Address", address(rbToken));
        console.log("WethRegistry Address", address(wethRegistry));
        console.log("MarketPlace Address", address(marketPlace));
        console.log("GetStepsApi Address", address(getstepsapi));
        console.log("WethReward Address", address(wethReward));
        console.log("DAOGoverner Address", address(rbgovernor));

    }
}

