// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MarketPlace} from "./Marketplace.sol";

contract Escrow{
    mapping(address => mapping(address =>uint256)) public s_buyerToSellerPayment;
    constructor(){
    }

    function updateBuyerPayment(address _buyer, address _seller, uint256 _amount) public{
        s_buyerToSellerPayment[_buyer][_seller] = _amount;
    }

    function payToSeller(address _seller) public{
        uint256 amount = s_buyerToSellerPayment[msg.sender][_seller];
        payable(_seller).transfer(amount);
    }

    function checkBuyerAndPayerRelation(address _buyer, address _seller) public view returns(uint256){
        return s_buyerToSellerPayment[_buyer][_seller];
    }
    receive() external payable {}
}