// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MarketPlace} from "../Marketplace.sol";
import {GetStepsAPI} from "../GoogleStepsApi.sol";
import {WethRegistry} from "../PoolModels/WethRegistry.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address s_owner) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract WethReward {
    MarketPlace public immutable i_marketplace;
    GetStepsAPI public immutable i_getStepsApi;
    WethRegistry public immutable i_wethRegistry;
    IWETH public immutable i_weth;

    uint256 public constant SCALING_FACTOR = 10 ** 3;

    mapping(address => uint256) public s_userSteps;
    mapping(address => uint256) public s_stepShareOfUser;
    mapping(address => uint256) public s_rbfsShareOfUser;

    mapping(uint256 => uint256) public s_totalStepsPerSlot;
    mapping(address => uint256) public s_userRewards;
    mapping(address => bool) public s_claimedReward;
    mapping(address => bool) public s_rewardCollectedByUser;

    mapping(address => uint256) public s_lastClaimTimestamp;

    constructor(address _wethToken, address _marketPlace, address _wethRegistry, address _getStepsApi) {
        i_getStepsApi = GetStepsAPI(_getStepsApi);
        i_marketplace = MarketPlace(_marketPlace);
        i_wethRegistry = WethRegistry(_wethRegistry);
        i_weth = IWETH(_wethToken);
    }

    /**
    * @dev this function will only be called if the Event from previous function is recorded true on frontend side..
    * or on frontEnd Side their is time dealy of 30 - 45 secs to call this function after first function
    */ 
    function recordFetchedSteps(address _account) public returns(uint256 userStepsInSlot, uint256 totalStepsInSlot){
        GetStepsAPI.DailyStepsData memory userStepsDailyData = i_getStepsApi.func_userStepsData(_account);
        uint256 userDailySteps = userStepsDailyData.stepsCount;
        s_userSteps[_account] = userDailySteps;

        uint256 userSlotId = i_wethRegistry._getUserSlotId(_account);
        s_totalStepsPerSlot[userSlotId] += userDailySteps;

        userStepsInSlot = userDailySteps;
        totalStepsInSlot = s_totalStepsPerSlot[userSlotId];

    }
    /**
     * @dev This function will be used to claim the reward,
     * @param _shoeId will be provided to calculate the reward for user,
     * this function will call internal funtion _calculateRewardOfUserSteps(msg.sender, _shoeId); which will do the
     * actual calculation is done.
     */
    function takeRewardBasedOnShoeId(uint256 _shoeId) public{
        require(i_marketplace.checkUserRegistraction(msg.sender),"User not registered");
        require(i_marketplace.hasPurchasedShoe(msg.sender, _shoeId),"You are not eligible");

        uint256 currentTimestamp = block.timestamp;
        uint256 lastClaimTimestamp = s_lastClaimTimestamp[msg.sender];

        uint256 nextMidnight = (currentTimestamp / 1 days) * 1 days + 1 days;

        require(currentTimestamp >= nextMidnight || currentTimestamp - lastClaimTimestamp >= 1 days, "Reward already claimed today");

        uint256 rewardAmount = _calculateRewardOfUserSteps(msg.sender, _shoeId);
        s_userRewards[msg.sender]= rewardAmount;
        i_weth.transferFrom(address(i_wethRegistry), msg.sender, rewardAmount);
        s_rewardCollectedByUser[msg.sender]=true;

        s_lastClaimTimestamp[msg.sender] = currentTimestamp;
    }
    /**
     * @dev this function will do the actual calculation for user's reward
     * the internal functions do the calculations based on steps share of user in his/her slot and also
     * the calculation based on rbFactor share in slot. 
     */
    function _calculateRewardOfUserSteps(address _account, uint256 _shoeId) public view returns(uint256){
        uint256 rewardOfUser = _calculateShareOfUsersStepsInSlot(_account) + _calculateShareOfUserRBfactorInSlot(_account, _shoeId);
        // s_userRewards[msg.sender]= rewardOfUser;
        return rewardOfUser;
    }

    /**
     * @dev this function will do the calculation based on user's steps share between yesterday 12:00 AM and today's 12:00 AM
     * the share will be among all the members in user's slot.
     */
    function _calculateShareOfUsersStepsInSlot(address _account) internal view returns(uint256){
        uint256 userSteps = s_userSteps[_account];
        uint256 userSlotId = i_wethRegistry._getUserSlotId(_account);
        uint256 totalStepsInSlot = s_totalStepsPerSlot[userSlotId];
        
        (, , , ,uint256 rewardFund,) = i_wethRegistry._getSlotData(userSlotId);

        // s_stepShareOfUser[_account] = (userSteps * rewardFund * SCALING_FACTOR)/totalStepsInSlot;
        // s_stepShareOfUser[_account] = (userSteps * rewardFund)/totalStepsInSlot;
        return (userSteps * rewardFund)/totalStepsInSlot;
    }

    /**
     * @dev this function will do the calculation based on user's shoe RB Factor of shoe share between yesterday 12:00 AM and today's 
     * 12:00 AM the share will be among all the members in user's slot.
     */
    function _calculateShareOfUserRBfactorInSlot(address _account, uint256 _shoeid) internal view returns(uint256){
        uint256 userSlotId = i_wethRegistry._getUserSlotId(_account);
        (, , , uint256[] memory rbfs , , uint256 rbRewardFund) = i_wethRegistry._getSlotData(userSlotId);

        uint256 totalrbfs;
        uint256 userrbfs = i_marketplace.getShoeRB_Factor(_shoeid);

        for(uint256 i=0; i<rbfs.length; i++){
            totalrbfs += rbfs[i];
        }

        // return (userrbfs * rbRewardFund * SCALING_FACTOR)/totalrbfs;
        return (userrbfs * rbRewardFund)/totalrbfs;
    }
    /**
     @dev 
     This function will record the user reward, user steps share and user rb share in the storage variable.
     */
    function _recordUserDatas(address _account, uint256 _shoeId) public {
        s_userRewards[msg.sender] = _calculateRewardOfUserSteps(_account, _shoeId);
        s_stepShareOfUser[_account] = _calculateShareOfUsersStepsInSlot(_account);
        s_rbfsShareOfUser[_account] = _calculateShareOfUserRBfactorInSlot(_account, _shoeId);
    }

    //------------------------------------VIEW-FUNCTION------------------------------------------
    //-------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------

    function checkIfUserCollectedRewardOrNot(address _account) public view returns(bool){
        return s_rewardCollectedByUser[_account];
    }

    function checkIfUserEligibleForRewardOrNot(address _account, uint256 _shoeId) public view returns(bool){
        if(i_marketplace.checkUserRegistraction(_account) && i_marketplace.hasPurchasedShoe(_account, _shoeId)){
            return true;
        }
        return false;
    }
    
    function getStepsOfUserInSlot(address _account) public view returns(uint256){
        return s_userSteps[_account];
    }

    function getTotalStepsInSlot(uint256 _slotId) public view returns(uint256){
        return s_totalStepsPerSlot[_slotId];
    }

    function getStepsShareOfUser(address _account) public view returns(uint256){
        return s_stepShareOfUser[_account];
    }

    function getRewardDataOfUsers(address _account) public view returns(uint256){
        return s_userRewards[_account];
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function mint(address recipient, uint amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
