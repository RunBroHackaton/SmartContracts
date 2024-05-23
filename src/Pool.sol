// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// @dev
// In this contract the worth of a RB token is determined i.e what's the value of 1 RB token in ETH?
// It's calculated with simple formula - Balance of this contract collected suring last Month / Supply of RB Tokens for 1 Month

contract Pool {

    uint256 public totalSupplyof_RB_Tokens_In_OneMonth = 100_000;
    uint256 public startingTime;
    uint256 public startingBalance;
    uint256 public constant ONE_MONTH = 30 days;

    address public owner;

    constructor () {
        owner = msg.sender;
        startingTime = block.timestamp;
        startingBalance = address(this).balance;
    }


    // @dev
    // RB value is calculated, consedering funds in Pool.sol for Last 1 month and Total supply of RB tokens 
    function RB_TokenValue() public returns (uint256 valueOfA_RB_Token){
        require(msg.sender==owner,"Not owner");
        return valueOfA_RB_Token = getbalance_In_Duration_Of_OneMonth()/totalSupplyof_RB_Tokens_In_OneMonth; 
    }

    // Gives balance from deployment of Pool contract
    function getbalanceFromDeploymentDate() public view returns (uint256){
        return address(this).balance; 
    }

    // Gives balance of last Month
    function getbalance_In_Duration_Of_OneMonth() public returns (uint256){
        require(block.timestamp>= startingTime + ONE_MONTH);

        uint256 currentBalance = address(this).balance;
        uint256 tempBalance = startingBalance;
        startingTime = block.timestamp;
        startingBalance = address(this).balance;
        return currentBalance-tempBalance;
    }

    receive() external payable {

    }

    fallback() external payable { 
        
    }
}
