// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract WethRegistry{

    uint256 public s_reservebalance;

    function updateReserve(uint256 _amount) public {
        s_reservebalance += _amount;
    }

    

}