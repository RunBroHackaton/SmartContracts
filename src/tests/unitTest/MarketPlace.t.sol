// SPDX-License-Identifier: MIT

/// NOTE:
/// To run this test file, in the `Marketplace.sol` comment out the check
/// `require(kyc.checkIfSellerIsRegisteredOrNot(msg.sender), "KYC-Unverified");` in `list` function.

pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {MarketPlace} from "src/Marketplace.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";
import {MockWETH} from "src/tests/mocks/MockWETH.sol";
import {Escrow} from "src/Escrow.sol";
import {console} from "forge-std/console.sol";
import {RunBroToken} from "src/RunBroToken.sol";
import {KYC} from "src/NewKYC.sol";

contract MarketplaceTest is Test {
    MarketPlace marketplace;
    WethRegistry wethRegistry;
    MockWETH mweth;
    Escrow escrow;
    RunBroToken rbtoken;
    KYC kyc;
    address[] private usersABC;
    uint256[] private users123;
    function setUp() public {
        wethRegistry = new WethRegistry();
        mweth = new MockWETH();
        escrow = new Escrow();
        rbtoken = new RunBroToken(100000);
        marketplace = new MarketPlace(payable(address(wethRegistry)), payable(address(mweth)), payable(address(escrow)), address(rbtoken), address(kyc)); 
    }

    function testList() public {
        // Arrange
        address seller = address(1);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;

        // Act
        vm.deal(seller, 2 ether);
        vm.startPrank(seller);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);

        // Assert
        (uint256 id, string memory name, string memory brand, string memory image, uint256 cost, uint256 RB_Factor, uint256 quantity, address lister, bool payedToEscrow, bool payedToSeller, bool confirmationByBuyer, bool confirmationBySeller) = marketplace.s_shoes(1);
        assertEq(id, 1);
        assertEq(name, "Test Shoe");
        assertEq(brand, "Test Brand");
        assertEq(image, "test_image.png");
        assertEq(cost, 1 ether);
        assertEq(RB_Factor, 0.1 ether);
        assertEq(quantity, 1);
        assertEq(lister, seller);
        assertEq(payedToEscrow, false);
        assertEq(payedToSeller, false);

        // Check if the platform fee was transferred correctly
        assertEq(mweth.balanceOf(address(marketplace)), 0);
        assertEq(mweth.balanceOf(address(wethRegistry)), platformFee);
    }

    function testBuy() public {
        // Arrange
        address seller = address(1);
        address buyer = address(2);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;

        // Act
        vm.deal(seller, 2 ether);
        vm.deal(buyer, 2 ether);
        vm.startPrank(seller);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        vm.startPrank(buyer);
        wethRegistry._loadMarketPlace(address(marketplace));
        marketplace.buy{value: 1 ether}(1);

        // Assert
        (uint256 id, string memory name, string memory brand, string memory image, uint256 cost, uint256 RB_Factor, uint256 quantity, address lister, bool payedToEscrow, bool payedToSeller, bool confirmationByBuyer, bool confirmationBySeller) = marketplace.s_shoes(1);
        assertEq(id, 1);
        assertEq(name, "Test Shoe");
        assertEq(brand, "Test Brand");
        assertEq(image, "test_image.png");
        assertEq(cost, 1 ether);
        assertEq(RB_Factor, 0.1 ether);
        assertEq(quantity, 0);
        assertEq(lister, seller);
        assertEq(payedToEscrow, true);
        assertEq(payedToSeller, false);
        assertEq(confirmationByBuyer, false);
        assertEq(confirmationBySeller, false);

        // Check if the platform fee was transferred correctly
        assertEq(mweth.balanceOf(address(marketplace)), 0);
        assertEq(mweth.balanceOf(address(wethRegistry)), platformFee);

        // Check if the item cost was transferred correctly
        assertEq(address(escrow).balance, cost);
        assertEq(buyer.balance, 1 ether);
        assertEq(escrow.checkBuyerAndPayerRelation(buyer, seller), cost);
    }

    function testWethAllocation() public {
        // Arrange
        address seller = address(1);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;

        // Act
        vm.deal(seller, 2 ether);
        vm.startPrank(seller);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        // Assert
        assertEq(mweth.balanceOf(address(marketplace)), 0);
        assertEq(mweth.balanceOf(address(wethRegistry)), platformFee);
    }

    function testWethRegistryData() public {
        // Arrange
        address seller = address(1);
        address buyer = address(2);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;
        
        // Act
        vm.deal(seller, 2 ether);
        vm.deal(buyer, 2 ether);
        vm.startPrank(seller);
        console.log("Reserve Balance Before Listing", wethRegistry.s_reservebalance());
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        console.log("Reserve Balance After Listing", wethRegistry.s_reservebalance());
        vm.stopPrank();

        vm.startPrank(buyer);
        wethRegistry._loadMarketPlace(address(marketplace));
        marketplace.buy{value: 1 ether}(1);

        // Assert
        assertEq(wethRegistry.s_reservebalance(), platformFee, "A");
        assertEq(wethRegistry.s_currentNumberOfSlots(), 0, "B");
        assertEq(wethRegistry._getUserSlotId(buyer), 0, "C");
        (uint256 slotId, uint256 numberOfUsers, address[] memory users, uint256[] memory rbfs, uint256 rewardFund, uint256 rbRewardFund) = wethRegistry._getSlotData(0);
        assertEq(slotId, 0, "D");
        assertEq(numberOfUsers, 1, "E");
        assertEq(users.length, 1, "F");
        assertEq(rewardFund, 0, "G");
    }

    function createRandomUsers(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            usersABC.push(address(uint160(uint256(keccak256(abi.encodePacked(i, block.timestamp))))));
        }
    }

    function createRandomrbfs(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            users123.push(10*(i+1));
        }
    }

    function testUserLimitInSlot() public {
        // Arrange
        address seller = address(1);
        address buyer = address(2);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;

        // Act
        vm.deal(seller, 2 ether);
        vm.deal(buyer, 2 ether);
        vm.startPrank(seller);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        createRandomUsers(100);
        createRandomrbfs(100);
        wethRegistry.setRandomSlotData(0, 100, usersABC, users123, 0,0);

        vm.startPrank(buyer);
        wethRegistry._loadMarketPlace(address(marketplace));
        marketplace.buy{value: 1 ether}(1);


        console.log("Total Number Of Slots", wethRegistry.s_currentNumberOfSlots());

        // Assert
        assertEq(wethRegistry.s_reservebalance(), platformFee, "A");
        assertEq(wethRegistry.s_currentNumberOfSlots(), 1, "B");
        assertEq(wethRegistry._getUserSlotId(buyer), 1, "C");
        (uint256 slotId, uint256 numberOfUsers, address[] memory users, uint256[] memory rbfs, uint256 rewardFund, uint256 rbRewardFund) = wethRegistry._getSlotData(1);
        assertEq(slotId, 1, "D");
        assertEq(numberOfUsers, 1, "E");
        assertEq(users.length, 1, "F");
        assertEq(rewardFund, 0, "G");
    }

    function testFundDistributionToSlots() public {
        // Arrange
        address seller = address(1);
        address buyer = address(2);
        uint256 itemCost = 1 ether;
        uint256 itemRB_Factor = 0.1 ether;
        uint256 platformFee = (itemCost * 10) / 100 + (itemRB_Factor * 10) / 100;
        uint256 creditcardNumber = 1234;

        // Act
        vm.deal(seller, 2 ether);
        vm.deal(buyer, 2 ether);
        vm.startPrank(seller);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        createRandomUsers(100);
        createRandomrbfs(100);
        wethRegistry.setRandomSlotData(0, 100, usersABC, users123, 0,0);

        vm.startPrank(buyer);
        wethRegistry._loadMarketPlace(address(marketplace));
        marketplace.buy{value: 1 ether}(1);

        wethRegistry.distributeBalanceToSlot();
        uint256 reserveBalance = wethRegistry.s_reservebalance();

        console.log("Total Number Of Slots", wethRegistry.s_currentNumberOfSlots());

        // Assert
        assertEq(wethRegistry.s_reservebalance(), reserveBalance, "A");
        assertEq(wethRegistry.s_currentNumberOfSlots(), 1, "B");
        assertEq(wethRegistry._getUserSlotId(buyer), 1, "C");
        (uint256 slotId, uint256 numberOfUsers, address[] memory users, uint256[] memory rbfs, uint256 rewardFund, uint256 rbRewardFund) = wethRegistry._getSlotData(1);
        console.log("AAAAAAAAAAAAAAAAAAAAAAAAAAA", users[0]);
        console.log("BBBBBBBBBBBBBBBBBBBBBBBBBBB", rbfs[0]);
        console.log("CCCCCCCCCCCCCCCCCCCCCCCCCCC", rewardFund);
        console.log("DDDDDDDDDDDDDDDDDDDDDDDDDDD", rbRewardFund);
        assertEq(slotId, 1, "D");
        assertEq(numberOfUsers, 1, "E");
        assertEq(users.length, 1, "F");
        assertEq(rewardFund, 80*reserveBalance/(2*100), "G");
        assertEq(rbRewardFund, 20*reserveBalance/(2*100), "H" );
    }

}
