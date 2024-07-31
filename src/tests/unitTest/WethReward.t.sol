// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {WethReward} from "src/RewardModels/WethRewardModel.sol";
import {MarketPlace} from "src/Marketplace.sol";
import {GetStepsAPI} from "src/GoogleStepsApi.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";
import {MockWETH} from "src/tests/mocks/MockWETH.sol";

contract WethRewardTest is Test {
    WethReward public wethReward;
    MarketPlace public marketPlace;
    GetStepsAPI public getStepsApi;
    WethRegistry public wethRegistry;
    MockWETH public mweth;
    address public owner;
    address public addr1;
    address public addr2;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        // Deploy mock contracts
        marketPlace = new MarketPlace();
        getStepsApi = new GetStepsAPI();
        wethRegistry = new WethRegistry();
        mweth = new MockWETH();

        // Deploy WethReward contract
        wethReward = new WethReward(address(mweth), address(marketPlace), address(wethRegistry), address(getStepsApi));
    }

    function testSendRequestToFetchSteps() public {
        wethReward.sendRequestToFetchSteps("authToken");
        // Add assertions based on the expected behavior of sendRequestToFetchSteps
    }

    function testRecordFetchedSteps() public {
        // Mock the response of getStepsApi.func_userStepsData
        getStepsApi.setUserStepsData(addr1, 1000);
        wethReward.recordFetchedSteps(addr1);
        assertEq(wethReward.s_userSteps(addr1), 1000);
    }

    function testTakeRewardBasedOnShoeId() public {
        // Mock the necessary functions and data
        marketPlace.setUserRegistration(addr1, true);
        marketPlace.setUserShoe(addr1, 1, true);
        marketPlace.setShoeRB_Factor(1, 2);

        wethRegistry.setUserSlotId(addr1, 1);
        wethRegistry.setSlotData(1, 0, 0, 0, 1000);

        getStepsApi.setUserStepsData(addr1, 1000);
        wethReward.recordFetchedSteps(addr1);

        wethReward.takeRewardBasedOnShoeId(1);
        // Add assertions based on the expected behavior of takeRewardBasedOnShoeId
    }
}