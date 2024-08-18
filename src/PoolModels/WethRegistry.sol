// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {MarketPlace} from "../Marketplace.sol";
import "forge-std/console.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address s_owner) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract WethRegistry is AutomationCompatibleInterface{
    uint256 public s_reservebalance;
    uint256 public s_currentNumberOfSlots;
    uint256 constant public MAX_USERS_PER_SLOT = 100;
    uint256 constant SCALE = 10**3;
    uint256 distributionTimeStamp;

    MarketPlace public i_marketplace;
    
    /**
     * Slots are where 100 users will be stored, next 100 in other slot.    
     */
    struct Slot{
        uint256 slotId;
        uint256 numberOfUsers;
        address[] users;
        uint256[] rbfs; 
        uint256 rewardFund;
        uint256 rbRewardFund;
    }

    mapping(uint256 slotId => Slot) public s_slot;
    mapping(address => uint256) public s_userSlotId;

    // RBs
    mapping(uint256 => uint256) public s_totalRbFactorsInSlot;


    function _createSlot(uint256 _slotId) internal {
        s_slot[_slotId].slotId = _slotId;
        s_slot[_slotId].numberOfUsers = 0;
    }

    function _loadMarketPlace(address _marketplace) public {
        i_marketplace = MarketPlace(_marketplace);
    }

    function _doApprovalToWethReward(address weth, address wethRewardmodel) public{
        uint256 max = type(uint256).max;
        IWETH(weth).approve(wethRewardmodel, max);
    }

    function _addUserToSlot(uint256 _slotId, address _user) public {
        if(s_slot[_slotId].numberOfUsers >= MAX_USERS_PER_SLOT){
            _updateSlotCountAndCreateNewSlot();
            uint256 latestSlotNumber = s_currentNumberOfSlots;
            s_slot[latestSlotNumber].users.push(_user);
            s_slot[latestSlotNumber].rbfs.push(i_marketplace.getShoeRB_Factor(i_marketplace.getShoeIdsOwnedByUser(_user)[0]));
            s_slot[latestSlotNumber].numberOfUsers++;
            s_userSlotId[_user] = latestSlotNumber;
        } else {
            uint256[] memory shoesByUser = i_marketplace.getShoeIdsOwnedByUser(_user);
            uint256 mostOldestShoeId = shoesByUser[0];
            uint256 rbFactor = i_marketplace.getShoeRB_Factor(mostOldestShoeId);
            
            s_slot[_slotId].users.push(_user);
            s_slot[_slotId].rbfs.push(rbFactor);
            s_slot[_slotId].numberOfUsers++;
            s_userSlotId[_user] = _slotId;
        }
    }

    function _updateSlotCountAndCreateNewSlot() internal {
        s_currentNumberOfSlots++;
        _createSlot(s_currentNumberOfSlots);
    }

    function _updateReserveBalance(uint256 _amount) public {
        s_reservebalance += _amount;
    }

    function setRandomSlotData(
        uint256 _slotId, 
        uint256 _numberOfUsers, 
        address[] memory _users, 
        uint256[] memory _rbfs, 
        uint256 _rewardFund, 
        uint256 _rbrewardFund) public {
        s_slot[_slotId].slotId = _slotId;
        s_slot[_slotId].numberOfUsers = _numberOfUsers;
        s_slot[_slotId].users = _users;
        s_slot[_slotId].rewardFund = _rewardFund;
        s_slot[_slotId].rbfs = _rbfs;
        s_slot[_slotId].rbRewardFund = _rbrewardFund;


    }

    // This function will be called by chainlink automation.
    function distributeBalanceToSlot() public {
        uint256 balancePerSlot = (s_reservebalance)/(s_currentNumberOfSlots+1);

        uint256 rewardFundBasedOnSteps = (80 * balancePerSlot)/100;
        uint256 rewardFundBasedOnRBFactor = (20 * balancePerSlot)/100;

        for (uint256 i=0; i<=s_currentNumberOfSlots+1; i++){
            s_slot[i].rewardFund = rewardFundBasedOnSteps;
            s_slot[i].rbRewardFund = rewardFundBasedOnRBFactor;       
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

    function _getSlotData(uint256 _slotId) public view returns(uint256, uint256, address[] memory, uint256[] memory, uint256, uint256) {
        return (s_slot[_slotId].slotId, s_slot[_slotId].numberOfUsers, s_slot[_slotId].users, s_slot[_slotId].rbfs,  s_slot[_slotId].rewardFund, s_slot[_slotId].rbRewardFund);
    }

    function _getUserSlotId(address _user) public view returns(uint256) {
        return s_userSlotId[_user];
    }

    function _getCurrentNumberOfSlots() public view returns(uint256){
        return s_currentNumberOfSlots+1;
    }

    function rewardAllotmentToDifferentSlots() public view returns(uint256){
        uint256 noOfSlots = s_currentNumberOfSlots;
        return (s_reservebalance)/noOfSlots;
    }
}