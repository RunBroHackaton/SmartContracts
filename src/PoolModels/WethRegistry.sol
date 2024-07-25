// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract WethRegistry{
    uint256 public s_reservebalance;
    uint256 public s_numberOfSlots;

    struct Slots{
        uint256 slotId;
        uint256 numberOfUsers;
        address[] users;
    }

    function updateReserveBalance(uint256 _amount) public {
        s_reservebalance += _amount;
    }

    function getReserveBalance() public view returns(uint256){
        return s_reservebalance;
    }

    function distributeReserveBalance(address _to) public {
        uint256 balanceToDistribute = address(this).balance;
        (bool success, ) = payable(_to).call{value: balanceToDistribute}(abi.encodeWithSignature("rewardReceived(uint256)", balanceToDistribute));
        require(success, "Transfer failed");
    }

    function rewardAllotmentToDifferentSlots() public view returns(uint256){
        uint256 noOfSlots = s_numberOfSlots;
        return getReserveBalance()/noOfSlots;
    }

}