// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {MarketPlace} from "../Marketplace.sol";
import {Reward} from "../RewardModels/RewardModel3.sol";
import {GetStepsAPI} from "../GSA_V6.sol";

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
    //     0x52eF3d68BaB452a294342DC3e5f464d7f610f72E; // On Amoy
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
        PoolModel2 pool = new PoolModel2(wethAddress, address(rbToken));
        rbToken.approve(address(pool), initial_rbTokens_inPool);
        IWETH(wethAddress).approve(address(pool), initial_weth_inPool);

        pool.setIntialBalanceOfpool(initial_rbTokens_inPool);

        console.log(
            "Amount of WETH in Pool",
            IWETH(wethAddress).balanceOf(address(pool))
        );
        console.log(
            "Amount of RBToken in Pool",
            rbToken.balanceOf(address(pool))
        );

        MarketPlace marketPlace = new MarketPlace(payable(address(pool)), payable(wethAddress));
        GetStepsAPI getstepsapi = new GetStepsAPI();
        Reward reward = new Reward(address(rbToken), address(marketPlace), address(pool), address(getstepsapi));
        
        vm.stopBroadcast();

        console.log("RB Token Address", address(rbToken));
        console.log("Pool Address", address(pool));
        console.log("Marketplace Address", address(marketPlace));
        console.log("getStepsApi Address", address(getstepsapi));
        console.log("Reward Address", address(reward));

    }
}

