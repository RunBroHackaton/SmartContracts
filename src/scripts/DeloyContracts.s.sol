// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {MarketPlace} from "../Marketplace.sol";
import {Reward} from "../RewardModels/RewardModel3.sol";

contract DeployContracts is Script {
    address public owner = makeAddr("owner");
    address public wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // On Sepolia
    uint256 public initialSupply = 1000000 * 10 ** 18;
    uint256 public initial_rbTokens = 10000 * 10 ** 18;

    address public seller = address(1);
    address public buyer = address(2);

    function run() external {
        vm.startBroadcast();
        vm.prank(owner);
        RunBroToken rbToken = new RunBroToken(initialSupply);
        PoolModel2 pool = new PoolModel2(wethAddress, address(rbToken));
        rbToken.approve(address(pool), initial_rbTokens);
        pool.setIntialBalanceOfpool(initial_rbTokens);
        //-------------------------------------------------------------------------------------------
        MarketPlace marketPlace = new MarketPlace(
            payable(address(pool)),
            payable(wethAddress)
        );
        vm.stopPrank();

        vm.startPrank(seller);
        marketPlace.list(0, "A1", "B1", "C1", 120, 150, 1);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketPlace.buy(0);
        vm.stopPrank();
        //-------------------------------------------------------------------------------------------
        vm.startPrank(owner);
        Reward reward = new Reward(
            address(rbToken),
            address(marketPlace),
            address(pool)
        );
        reward.calculateReward(buyer, 0);
        vm.stopPrank();

        vm.startPrank(buyer);
        reward.claimReward(0);
        vm.stopPrank();

        vm.stopBroadcast();
    }
}
