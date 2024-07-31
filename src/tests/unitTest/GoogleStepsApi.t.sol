// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {GetStepsAPI} from "src/GoogleStepsApi.sol";
// import {WethRegistry} from "src/PoolModels/WethRegistry.sol";

// contract GetStepsAPITest is Test {
//     GetStepsAPI private getStepsAPI;
//     WethRegistry private wethRegistry;
//     address private constant ROUTER_ADDRESS = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
//     uint64 private constant SUBSCRIPTION_ID = 3004;
//     uint32 private constant GAS_LIMIT = 300000;
//     bytes32 private constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

//     function setUp() public {
//         wethRegistry = new WethRegistry();
//         getStepsAPI = new GetStepsAPI(address(wethRegistry));
//     }

//     function testInitialization() public {
//         assertEq(getStepsAPI.s_distributionTimeStamp(), getStepsAPI.getNext6PM(block.timestamp));
//     }

//     function testSendRequest() public {
//         string[] memory args = new string[](0);
//         string memory authToken = "testAuthToken";
//         bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

//         // Ensure requestId is not zero
//         assert(requestId != bytes32(0));
//         assertEq(getStepsAPI.requestIdToAddress(requestId), address(this));
//     }

//     function testFulfillRequest() public {
//         string[] memory args = new string[](0);
//         string memory authToken = "testAuthToken";
//         bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

//         // Mock response
//         bytes memory response = abi.encode(uint256(1000));
//         bytes memory error = new bytes(0);

//         getStepsAPI.fulfillRequest(requestId, response, error);

//         // Check if the data is correctly stored
//         GetStepsAPI.DailyStepsData memory stepsData = getStepsAPI.getLatestUserStepsData(address(this));
//         assertEq(stepsData.stepsCount, 1000);
//         assertEq(stepsData.requester, address(this));
//         assertEq(stepsData.dataType, "daily_steps");

//         // Ensure total steps count is updated
//         assertEq(getStepsAPI.totalStepsByAllUsersOnPreviousDay(), 1000);
//     }

//     function testGetAllDailyStepDataRecords() public {
//         string[] memory args = new string[](0);
//         string memory authToken = "testAuthToken";
//         bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

//         // Mock response
//         bytes memory response = abi.encode(uint256(1000));
//         bytes memory error = new bytes(0);

//         getStepsAPI.fulfillRequest(requestId, response, error);

//         GetStepsAPI.DailyStepsData[] memory stepsDataRecords = getStepsAPI.getAllDailyStepDataRecords();
//         assertEq(stepsDataRecords.length, 1);
//         assertEq(stepsDataRecords[0].stepsCount, 1000);
//         assertEq(stepsDataRecords[0].requester, address(this));
//         assertEq(stepsDataRecords[0].dataType, "daily_steps");
//     }

//     function testUpdateRewardDistributionTime() public {
//         // Move forward in time to pass the initial distribution time
//         vm.warp(block.timestamp + 1 days);

//         getStepsAPI.updateRewardDistributionTime();

//         // Ensure the distribution time is updated
//         assertEq(getStepsAPI.s_distributionTimeStamp(), getStepsAPI.getNext6PM(block.timestamp));
//     }
// }
