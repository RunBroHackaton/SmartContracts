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

    function run() external {
        // console.log("OWNER'S BALANCE IN ETH", owner.balance);
        owner = msg.sender;
        vm.startBroadcast(owner);

        RunBroToken rbToken = new RunBroToken(initialSupply);
        Escrow escrow = new Escrow();

        WethRegistry wethRegistry = new WethRegistry();
        MarketPlace marketPlace = new MarketPlace(address(wethRegistry), wethAddress, payable(address(escrow)));
        
        GetStepsAPI getstepsapi = new GetStepsAPI(address(wethRegistry));
        WethReward wethReward = new WethReward(wethAddress, address(marketPlace), payable(address(wethRegistry)), address(getstepsapi));
        
        vm.stopBroadcast();

        console.log("RB Token Address", address(rbToken));
        console.log("WethRegistry Address", address(wethRegistry));
        console.log("MarketPlace Address", address(marketPlace));
        console.log("GetStepsApi Address", address(getstepsapi));
        console.log("Reward Address", address(wethReward));

    }
}

