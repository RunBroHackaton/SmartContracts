// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AccountRegistry{
    mapping(address=>bool) public s_userRegistration;
    function addUserToPlatform(address _account) public {
        s_userRegistration[_account]=true;
    }
}