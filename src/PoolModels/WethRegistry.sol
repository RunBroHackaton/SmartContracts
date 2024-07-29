// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract WethRegistry{
    uint256 public s_reservebalance;
    uint256 public s_currentNumberOfSlots;
    uint256 constant public MAX_USERS_PER_SLOT = 100;
    uint256 constant SCALE = 10**3;

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
        if(s_slot[_slotId].numberOfUsers >= 100){
            _updateSlotCountAndCreateNewSlot();
            uint256 latestSlotNumber = s_currentNumberOfSlots;
            s_slot[latestSlotNumber].users.push(_user);
            s_slot[latestSlotNumber].numberOfUsers++;
        } else {
            s_slot[_slotId].users.push(_user);
            s_slot[_slotId].numberOfUsers++;
        }
    }

    function _updateSlotCountAndCreateNewSlot() internal {
        require(s_slot[s_currentNumberOfSlots].numberOfUsers >= 100, "Slot is not full yet");
        s_currentNumberOfSlots++;
        _createSlot(s_currentNumberOfSlots);
    }

    function _updateReserveBalance(uint256 _amount) public {
        s_reservebalance += _amount;
    }

//  This function will be called by chainlink automation.
    function distributeBalanceToSlot() public {
        uint256 balancePerSlot = (s_reservebalance*SCALE)/s_currentNumberOfSlots;

        for (uint256 i=1; i<=s_currentNumberOfSlots; i++){
            s_slot[i].rewardFund = balancePerSlot;       
        }
        require(address(this).balance == 0, "Balance not cleared");
    }

    function rewardAllotmentToDifferentSlots() public view returns(uint256){
        uint256 noOfSlots = s_currentNumberOfSlots;
        return _getRese
        rveBalance()/noOfSlots;
    }
    // -----------------------------VIEW FUNCTIONS-----------------------------------------
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
        return s_currentNumberOfSlots
    }
}