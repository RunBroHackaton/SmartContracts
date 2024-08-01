// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
contract WethRegistry is AutomationCompatibleInterface{
    uint256 public s_reservebalance;
    uint256 public s_currentNumberOfSlots;
    uint256 constant public MAX_USERS_PER_SLOT = 100;
    uint256 constant SCALE = 10**3;
    uint256 distributionTimeStamp;
    
    struct Slot{
        uint256 slotId;
        uint256 numberOfUsers;
        address[] users;
        uint256 rewardFund;
    }

    mapping(uint256 slotId => Slot) public s_slot;
    mapping(address => uint256) public s_userSlotId;

    function _createSlot(uint256 _slotId) internal {
        s_slot[_slotId].slotId = _slotId;
        s_slot[_slotId].numberOfUsers = 0;
    }

    function _addUserToSlot(uint256 _slotId, address _user) public {
        if(s_slot[_slotId].numberOfUsers >= MAX_USERS_PER_SLOT){
            _updateSlotCountAndCreateNewSlot();
            uint256 latestSlotNumber = s_currentNumberOfSlots;
            s_slot[latestSlotNumber].users.push(_user);
            s_slot[latestSlotNumber].numberOfUsers++;
            s_userSlotId[_user] = latestSlotNumber;
        } else {
            s_slot[_slotId].users.push(_user);
            s_slot[_slotId].numberOfUsers++;
            s_userSlotId[_user] = _slotId;
        }
    }

    function _updateSlotCountAndCreateNewSlot() internal {
        require(s_slot[s_currentNumberOfSlots].numberOfUsers >= MAX_USERS_PER_SLOT, "Slot is not full yet");
        s_currentNumberOfSlots++;
        _createSlot(s_currentNumberOfSlots);
    }

    function _updateReserveBalance(uint256 _amount) public {
        s_reservebalance += _amount;
    }

    function setRandomSlotData(uint256 _slotId, uint256 _numberOfUsers, address[] memory _users, uint256 _rewardFund) public {
        s_slot[_slotId].slotId = _slotId;
        s_slot[_slotId].numberOfUsers = _numberOfUsers;
        s_slot[_slotId].users = _users;
        s_slot[_slotId].rewardFund = _rewardFund;
    }

    // This function will be called by chainlink automation.
    function distributeBalanceToSlot() public {
        uint256 balancePerSlot = (s_reservebalance)/(s_currentNumberOfSlots+1);

        for (uint256 i=1; i<=s_currentNumberOfSlots; i++){
            s_slot[i].rewardFund = balancePerSlot;       
        }
        require(address(this).balance == 0, "Balance not cleared");
        distributionTimeStamp = block.timestamp;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - distributionTimeStamp) >= 24 hours;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - distributionTimeStamp) > 24 hours) {
            distributionTimeStamp = block.timestamp;
        }
    }

    //------------------------------VIEW FUNCTIONS-----------------------------------------
    //-------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------
    function _getReserveBalance() public view returns(uint256) {
        return s_reservebalance;
    }

    function _getSlotData(uint256 _slotId) public view returns(uint256, uint256, address[] memory, uint256) {
        return (s_slot[_slotId].slotId, s_slot[_slotId].numberOfUsers, s_slot[_slotId].users, s_slot[_slotId].rewardFund);
    }

    function _getUserSlotId(address _user) public view returns(uint256) {
        return s_userSlotId[_user];
    }

    function _getCurrentNumberOfSlots() public view returns(uint256){
        return s_currentNumberOfSlots;
    }

    function rewardAllotmentToDifferentSlots() public view returns(uint256){
        uint256 noOfSlots = s_currentNumberOfSlots;
        return (s_reservebalance)/noOfSlots;
    }
}