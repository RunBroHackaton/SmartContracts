// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {WethReward} from "src/RewardModels/WethRewardModel.sol";
import {MarketPlace} from "src/Marketplace.sol";
import {GetStepsAPI} from "src/GoogleStepsApi.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";
import {Escrow} from "src/Escrow.sol";
import {MockWETH} from "src/tests/mocks/MockWETH.sol";
import {MockGoogleStepsApi} from "src/tests/mocks/MockGoogleStepsApi.sol";


contract WethRewardTest is Test {
    WethReward public wethReward;
    MarketPlace public marketPlace;
    WethRegistry public wethRegistry;
    Escrow public escrow;
    MockWETH public mweth;
    MockGoogleStepsApi public mockgetStepsApi;
    address public owner;
    address public addr1;
    address public addr2;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        // Deploy contracts
        mockgetStepsApi = new MockGoogleStepsAPI();
        wethRegistry = new WethRegistry();
        mweth = new MockWETH();
        marketPlace = new MarketPlace(address(wethRegistry), address(mweth), address(escrow));
        wethReward = new WethReward(address(mweth), address(marketPlace), address(wethRegistry), address(mockgetStepsApi));
    }

    function testRewardToUserPerSlot() public {
        // Arrange
        address seller = address(1);
        address buyer = address(2);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;
        string memory authToken = 'abc';
        
        // Act
        vm.deal(seller, 2 ether);
        vm.deal(buyer, 2 ether);
        vm.startPrank(seller);
        marketplace.SellerRegisteration(creditcardNumber);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.buy{value: 1 ether}(1);

        wethReward.sendRequestToFetchSteps(authToken);
        wethReward.recordFetchedSteps(buyer);

        wethReward.takeRewardBasedOnShoeId(1);

        assertGt(wethReward.getRewardDataOfUsers(buyer), 0);

    }

        // // Assert
        // assertEq(wethRegistry.s_reservebalance(), platformFee, "A");
        // assertEq(wethRegistry.s_currentNumberOfSlots(), 0, "B");
        // assertEq(wethRegistry._getUserSlotId(buyer), 0, "C");
        // (uint256 slotId, uint256 numberOfUsers, address[] memory users, uint256 rewardFund) = wethRegistry._getSlotData(0);
        // assertEq(slotId, 0, "D");
        // assertEq(numberOfUsers, 1, "E");
        // assertEq(users.length, 1, "F");
        // assertEq(rewardFund, 0, "G");

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