// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {MarketPlace} from "../Marketplace.sol";
import {WethReward} from "../RewardModels/WethRewardModel.sol";
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
    WethReward public i_wethReward;

    address public owner;
    constructor(){
        owner = msg.sender;
    }
    
    /**
     * @dev Slots are where 100 users will be stored, next 100 in other slot.
     * it will contain it's unique slotId
     * total number of users in slot (MAX is 100)
     * array of addresses of different users
     * array of rbfs (rb factor of shoes) of different users
     * rewardFund is 80% of fund allocated to slot, during reward distribution to slots 
     [from this fund reward for users based on steps will be calculated]
     * rbRewardFund is 20% of fund allocated to slot, during reward distribution to slots 
     [from this fund reward for users based on rbFactor will be calculated]   
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
    /**
    @dev this function will be called during deployment, to load the marketplace interface at it's deployed address
     */
    function _loadMarketPlace(address _marketplace) public {
        i_marketplace = MarketPlace(_marketplace);
    }
    /**
    @dev this function will be called during deployment, to load the wethReward interface at it's deployed address.
     */
    function _loadWethReward(address _wethReward) public {
        i_wethReward = WethReward(_wethReward);
    }
    /**
    @dev this function will be called during deployment, to approve the wethReward contract to spend from it's address.
    this will be relevant when user claims his/her reward from platform.
     */
    function _doApprovalToWethReward(address weth, address wethRewardmodel) public{
        uint256 max = type(uint256).max;
        IWETH(weth).approve(wethRewardmodel, max);
    }
    /**
     @dev When user purchases the shoe from marketplace, they will added in the Slot
     * What is Slot?
     * Slot is like container that will store the datas of consecutive 100 users.
     * so basically, this function adds the user is the latest vacant slot avalaible
     * Why need of Slot?
     * To make the competition only among 100 user (as slot conatains MAX 100 users) not all the users in platform.
     */
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

    /**
    @dev This function is just for testing purpose.
     */
    function setRandomSlotData(
        uint256 _slotId, 
        uint256 _numberOfUsers, 
        address[] memory _users, 
        uint256[] memory _rbfs, 
        uint256 _rewardFund, 
        uint256 _rbrewardFund) public {

        require(msg.sender == owner, "Only owner can call this function");
        
        s_slot[_slotId].slotId = _slotId;
        s_slot[_slotId].numberOfUsers = _numberOfUsers;
        s_slot[_slotId].users = _users;
        s_slot[_slotId].rewardFund = _rewardFund;
        s_slot[_slotId].rbfs = _rbfs;
        s_slot[_slotId].rbRewardFund = _rbrewardFund;
    }

    /**
     @dev This function will be called by chainlink automation at 12:00 AM Daily.
     */ 
    function distributeBalanceToSlot() public {
        uint256 balancePerSlot = (s_reservebalance)/(s_currentNumberOfSlots+1);

        uint256 rewardFundBasedOnSteps = (80 * balancePerSlot)/100;
        uint256 rewardFundBasedOnRBFactor = (20 * balancePerSlot)/100;

        for (uint256 i=0; i<=s_currentNumberOfSlots+1; i++){
            s_slot[i].rewardFund = rewardFundBasedOnSteps;
            s_slot[i].rbRewardFund = rewardFundBasedOnRBFactor;       
        }
        uint256 totalDistributed = rewardFundBasedOnSteps * (s_currentNumberOfSlots + 1) + rewardFundBasedOnRBFactor * (s_currentNumberOfSlots + 1);
        require(totalDistributed <= s_reservebalance, "Incorrect balance distribution");
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
            distributeBalanceToSlot();
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