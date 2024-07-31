// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";

contract WethRegistryTest is Test {
//     WethRegistry wethRegistry;
//     address addr1 = address(0x123);
//     address addr2 = address(0x456);

//     function setUp() public {
//         wethRegistry = new WethRegistry();
//     }

//     function testInitialValues() public {
//         assertEq(wethRegistry.s_reservebalance(), 0);
//         assertEq(wethRegistry.s_currentNumberOfSlots(), 0);
//     }

//     function testCreateSlot() public {
//         wethRegistry._createSlot(1);
//         (uint256 slotId, uint256 numberOfUsers, , ) = wethRegistry._getSlotData(1);
//         assertEq(slotId, 1);
//         assertEq(numberOfUsers, 0);
//     }

//     function testAddUserToSlot() public {
//         wethRegistry._createSlot(1);
//         wethRegistry._addUserToSlot(1, addr1);
//         (uint256 slotId, uint256 numberOfUsers, address[] memory users, ) = wethRegistry._getSlotData(1);
//         assertEq(numberOfUsers, 1);
//         assertEq(users[0], addr1);
//     }

//     function testUpdateReserveBalance() public {
//         wethRegistry._updateReserveBalance(1000);
//         assertEq(wethRegistry.s_reservebalance(), 1000);
//     }

//     function testDistributeBalanceToSlot() public {
//         wethRegistry._createSlot(1);
//         wethRegistry._updateReserveBalance(1000);
//         wethRegistry.distributeBalanceToSlot();
//         (, , , uint256 rewardFund) = wethRegistry._getSlotData(1);
//         assertEq(rewardFund, 1000 * 10**3);
//     }

//     function testGetReserveBalance() public {
//         wethRegistry._updateReserveBalance(1000);
//         assertEq(wethRegistry._getReserveBalance(), 1000);
//     }

//     function testGetSlotData() public {
//         wethRegistry._createSlot(1);
//         wethRegistry._addUserToSlot(1, addr1);
//         (uint256 slotId, uint256 numberOfUsers, address[] memory users, uint256 rewardFund) = wethRegistry._getSlotData(1);
//         assertEq(slotId, 1);
//         assertEq(numberOfUsers, 1);
//         assertEq(users[0], addr1);
//         assertEq(rewardFund, 0);
//     }

//     function testGetUserSlotId() public {
//         wethRegistry._createSlot(1);
//         wethRegistry._addUserToSlot(1, addr1);
//         assertEq(wethRegistry._getUserSlotId(addr1), 1);
//     }

//     function testGetCurrentNumberOfSlots() public {
//         wethRegistry._createSlot(1);
//         assertEq(wethRegistry._getCurrentNumberOfSlots(), 1);
//     }

//     function testRewardAllotmentToDifferentSlots() public {
//         wethRegistry._createSlot(1);
//         wethRegistry._updateReserveBalance(1000);
//         assertEq(wethRegistry.rewardAllotmentToDifferentSlots(), 1000);
//     }
  }