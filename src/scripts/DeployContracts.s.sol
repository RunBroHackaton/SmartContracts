// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {MarketPlace} from "../Marketplace.sol";
import {Reward} from "../RewardModels/RewardModel3.sol";
import {Interaction} from "../FrontendInteraction.sol";

contract DeployContracts is Script {
    // address public constant wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // On Sepolia
    address public constant wethAddress = 0x52eF3d68BaB452a294342DC3e5f464d7f610f72E; // On Amoy
    uint256 public initialSupply = 1000000 * 10 ** 18;
    uint256 public initial_rbTokens = 10000 * 10 ** 18;

    address public seller = address(1);
    address public buyer = address(2);

    function run() external returns(Interaction){
        address owner = msg.sender;
        
        // Ensure owner has enough ETH to deploy contracts
        vm.deal(owner, 1 ether);

        vm.startBroadcast(owner);

        uint256 startGas = gasleft();
        RunBroToken rbToken = new RunBroToken(initialSupply);
        uint256 endGas = gasleft();
        console.log("RunBroToken Deployment Gas Used:", startGas - endGas);

        startGas = gasleft();
        PoolModel2 pool = new PoolModel2(wethAddress, address(rbToken));
        endGas = gasleft();
        console.log("PoolModel2 Deployment Gas Used:", startGas - endGas);

        startGas = gasleft();
        MarketPlace marketPlace = new MarketPlace(
            payable(address(pool)),
            payable(wethAddress)
        );
        endGas = gasleft();
        console.log("MarketPlace Deployment Gas Used:", startGas - endGas);

        startGas = gasleft();
        Reward reward = new Reward(
            address(rbToken),
            address(marketPlace),
            address(pool)
        );
        endGas = gasleft();
        console.log("Reward Deployment Gas Used:", startGas - endGas);

        Interaction interaction = new Interaction(address(reward), address(pool), address(rbToken), address(marketPlace));

        vm.stopBroadcast();
        
        console.log("RB Token Address", address(rbToken));
        console.log("Pool Address", address(pool));
        console.log("Marketplace Address", address(marketPlace));
        console.log("Reward Address", address(reward));
        console.log("Interaction Address", address(interaction));
        return interaction;
    }
}

// pragma solidity ^0.8.18;

// import {Script, console} from "forge-std/Script.sol";
// import {RunBroToken} from "../RunBroToken.sol";
// import {PoolModel2} from "../PoolModels/PoolModel2.sol";
// import {MarketPlace} from "../Marketplace.sol";
// import {Reward} from "../RewardModels/RewardModel3.sol";

// contract DeployContracts is Script {
//     address public wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // On Sepolia
//     uint256 public initialSupply = 1000000 * 10 ** 18;
//     uint256 public initial_rbTokens = 10000 * 10 ** 18;

//     address public seller = address(1);
//     address public buyer = address(2);

//     function run() external {
//         vm.startBroadcast();

//         RunBroToken rbToken = new RunBroToken(initialSupply);
//         PoolModel2 pool = new PoolModel2(wethAddress, address(rbToken));
//         // rbToken.approve(address(pool), initial_rbTokens);
//         // pool.setIntialBalanceOfpool(initial_rbTokens);

//         MarketPlace marketPlace = new MarketPlace(
//             payable(address(pool)),
//             payable(wethAddress)
//         );
//         Reward reward = new Reward(
//             address(rbToken),
//             address(marketPlace),
//             address(pool)
//         );

//         vm.stopBroadcast();

//         // Seller lists an item
//         // vm.deal(seller, 1 ether);
//         // vm.startPrank(seller);
//         // marketPlace.list{value: 1500}(0, "Run", "Bro", "image url", 120, 150, 1);
//         // vm.stopPrank();

//         // Buyer buys the item
//         // vm.deal(buyer, 1 ether);
//         // vm.startPrank(buyer);
//         // marketPlace.buy{value: 1500}(0);
//         // vm.stopPrank();

//         // Buyer claims the reward
//         // vm.startPrank(buyer);
//         // reward.calculateReward(buyer, 0);
//         // reward.claimReward(0);
//         // vm.stopPrank();

//         console.log("RB Token Address", address(rbToken));
//         console.log("Pool Address", address(pool));
//         console.log("Marketplace Address", address(marketPlace));
//         console.log("Reward Address", address(reward));
//     }
// }


/**
 * @dev The code below needs to be sorted.
 * Cannot have vm.prank in deploy script
 *  you'll need to interact with them using the actual Ethereum accounts
 *          corresponding to the roles defined in your script (owner, seller, buyer)
 */

//    vm.prank(owner);
//         RunBroToken rbToken = new RunBroToken(initialSupply);
//         PoolModel2 pool = new PoolModel2(wethAddress, address(rbToken));
//         rbToken.approve(address(pool), initial_rbTokens);
//         pool.setIntialBalanceOfpool(initial_rbTokens);
//         //-------------------------------------------------------------------------------------------
//         MarketPlace marketPlace = new MarketPlace(
//             payable(address(pool)),
//             payable(wethAddress)
//         );
//         vm.stopPrank();

//         vm.startPrank(seller);
//         marketPlace.list(0, "A1", "B1", "C1", 120, 150, 1);
//         vm.stopPrank();

//         vm.startPrank(buyer);
//         marketPlace.buy(0);
//         vm.stopPrank();
//         //-------------------------------------------------------------------------------------------
//         vm.startPrank(owner);
//         Reward reward = new Reward(
//             address(rbToken),
//             address(marketPlace),
//             address(pool)
//         );
//         reward.calculateReward(buyer, 0);
//         vm.stopPrank();

//         vm.startPrank(buyer);
//         reward.claimReward(0);
//         vm.stopPrank();

//
