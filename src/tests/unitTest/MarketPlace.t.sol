// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {MarketPlace} from "src/Marketplace.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";
import {MockWETH} from "src/tests/mocks/MockWETH.sol";
import {Escrow} from "src/Escrow.sol";


contract MarketplaceTest is Test {
    MarketPlace marketplace;
    WethRegistry wethRegistry;
    MockWETH mweth;
    Escrow escrow;
    function setUp() public {
        wethRegistry = new WethRegistry();
        mweth = new MockWETH();
        escrow = new Escrow();
        marketplace = new MarketPlace(payable(address(wethRegistry)), payable(address(mweth)), payable(address(escrow))); 
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
        marketplace.SellerRegisteration(creditcardNumber);
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
        marketplace.SellerRegisteration(creditcardNumber);
        marketplace.list{value: platformFee}("Test Shoe", "Test Brand", "test_image.png", 1 ether, 0.1 ether, 1);
        vm.stopPrank();

        vm.startPrank(buyer);
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

    // Add more test functions here
}
