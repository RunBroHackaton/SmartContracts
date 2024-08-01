// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {GetStepsAPI} from "src/GoogleStepsApi.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";

contract GetStepsAPITest is Test {
    GetStepsAPI public getStepsAPI;
    WethRegistry public wethRegistry;

    address public owner = address(0x1);
    address public user = address(0x2);

    function setUp() public {
        wethRegistry = new WethRegistry();
        getStepsAPI = new GetStepsAPI(address(wethRegistry));
        vm.prank(owner);
    }

    function testInitializeContract() public {
        assertEq(getStepsAPI.s_contractCreationTime(), block.timestamp);
        assertEq(getStepsAPI.s_distributionTimeStamp(), getStepsAPI.getNext6PM(block.timestamp));
    }

    function testGetNext6PM() public {
        uint256 currentTimestamp = block.timestamp;
        uint256 next6PM = getStepsAPI.getNext6PM(currentTimestamp);
        uint256 expectedNext6PM = currentTimestamp / 1 days * 1 days + 18 hours;

        if (currentTimestamp >= expectedNext6PM) {
            expectedNext6PM += 1 days;
        }
        assertEq(next6PM, expectedNext6PM);
    }

    function testUpdateRewardDistributionTime() public {
        // Fast forward time to ensure the distribution time has passed
        vm.warp(getStepsAPI.s_distributionTimeStamp() + 1);

        getStepsAPI.updateRewardDistributionTime();
        assertEq(getStepsAPI.s_distributionTimeStamp(), getStepsAPI.getNext6PM(block.timestamp));
        assertEq(getStepsAPI.totalStepsByAllUsersOnPreviousDay(), 0);
    }

    function testSendRequest() public {
        vm.prank(user);

        string[] memory args = new string[](0);
        string memory authToken = "testAuthToken";

        bytes32 requestId = getStepsAPI.sendRequest(args, authToken);
        assertEq(getStepsAPI.s_lastRequestId(), requestId);
        assertEq(getStepsAPI.requestIdToAddress(requestId), user);
    }

    // function testFulfillRequest() public {
    //     vm.prank(user);

    //     string[] memory args = new string[](0);
    //     string memory authToken = "testAuthToken";

    //     bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

    //     bytes memory response = abi.encode(uint256(1000));
    //     bytes memory error = "";

    //     getStepsAPI.fulfillRequest(requestId, response, error);

    //     GetStepsAPI.DailyStepsData memory userSteps = getStepsAPI.func_userStepsData(user);
    //     assertEq(userSteps.stepsCount, 1000);
    //     assertTrue(getStepsAPI.hasUserFetchedData(user));
    //     assertEq(getStepsAPI.totalStepsByAllUsersOnPreviousDay(), 1000);
    // }

    // function testGetAllDailyStepDataRecords() public {
    //     vm.prank(user);

    //     string[] memory args = new string[](0);
    //     string memory authToken = "testAuthToken";

    //     bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

    //     bytes memory response = abi.encode(uint256(1000));
    //     bytes memory error = "";

    //     getStepsAPI.fulfillRequest(requestId, response, error);

    //     GetStepsAPI.DailyStepsData[] memory records = getStepsAPI.getAllDailyStepDataRecords();
    //     assertEq(records.length, 1);
    //     assertEq(records[0].stepsCount, 1000);
    // }

    // function testGetLatestUserStepsData() public {
    //     vm.prank(user);

    //     string[] memory args = new string[](0);
    //     string memory authToken = "testAuthToken";

    //     bytes32 requestId = getStepsAPI.sendRequest(args, authToken);

    //     bytes memory response = abi.encode(uint256(1000));
    //     bytes memory error = "";

    //     getStepsAPI.fulfillRequest(requestId, response, error);

    //     GetStepsAPI.DailyStepsData memory latestData = getStepsAPI.getLatestUserStepsData(user);
    //     assertEq(latestData.stepsCount, 1000);
    // }
}
