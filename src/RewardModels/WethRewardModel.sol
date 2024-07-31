// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    mapping(address => uint256) public s_startingTime;
    // user => time => numberOfSteps till that time
    mapping(address => mapping(uint256 => uint256)) public s_userStepsAtMoment;

    mapping(address => uint256) public s_userSteps;
    mapping(address => uint256) public s_stepShareOfUser;

    //Slot analysis
    uint256 public s_totalStepsByAllUsersInSlot;
    mapping(uint256 => uint256) public s_totalStepsPerSlot;
    mapping(address => uint256) public s_userRewards;

    constructor(address _wethToken, address _marketPlace, address _wethRegistry, address _getStepsApi) {
        i_getStepsApi = GetStepsAPI(_getStepsApi);
        i_marketplace = MarketPlace(_marketPlace);
        i_wethRegistry = WethRegistry(_wethRegistry);
        i_weth = IWETH(_wethToken);
    }

    /**
     * @dev This function will be called by user to retrive his steps.
     */ 
    function sendRequestToFetchSteps(string memory authToken) public{
        string[] memory args = new string[](1);
        args[0] = "0";
        i_getStepsApi.sendRequest(args, authToken);
    }

    /**
     * @dev this function will only be called if the Event from previous function is recorded true on frontend side..
     * or on frontEnd Side their is time dealy of 30 - 45 secs to call this function after first function
     */ 
    function recordFetchedSteps(address _account) public{
        GetStepsAPI.DailyStepsData memory userStepsDailyData = i_getStepsApi.func_userStepsData(_account);
        uint256 userDailySteps = userStepsDailyData.stepsCount;
        s_userSteps[msg.sender] = userDailySteps;

        uint256 userSlotId = i_wethRegistry._getUserSlotId(msg.sender);
        s_totalStepsPerSlot[userSlotId] += userDailySteps;
    }

    /**
     * @dev this function will only be called by user to claim his reward.
     */
    function takeRewardBasedOnShoeId(uint256 _shoeId) public{
        require(i_marketplace.checkUserRegistraction(msg.sender),"User not registered");
        require(i_marketplace.hasPurchasedShoe(msg.sender, _shoeId),"You are not eligible");

        uint256 rewardAmount = _calculateRewardOfUserSteps(msg.sender, _shoeId);
        s_userRewards[msg.sender]= rewardAmount;
        i_weth.transferFrom(address(i_wethRegistry), msg.sender, rewardAmount);
    }

    function _calculateRewardOfUserSteps(address _account, uint256 _shoeId) internal returns(uint256){
        uint256 RB_Factor = i_marketplace.getShoeRB_Factor(_shoeId);
        uint256 rewardOfUser = _calculateShareOfUsersStepsInSlot(_account) * RB_Factor ;
        return rewardOfUser;
    }
    function _calculateShareOfUsersStepsInSlot(address _account) internal returns(uint256){
        uint256 userSteps = s_userSteps[_account];
        uint256 userSlotId = i_wethRegistry._getUserSlotId(_account);
        uint256 totalStepsInSlot = s_totalStepsPerSlot[userSlotId];
        
        (, , ,uint256 rewardFund) = i_wethRegistry._getSlotData(userSlotId);

        s_stepShareOfUser[_account] = (userSteps * rewardFund * SCALING_FACTOR)/totalStepsInSlot;
        return s_stepShareOfUser[_account];
    }

    function getRewardDataOfUsers(address _account) public view returns(uint256){
        return s_userRewards[_account];
    }

    function createMockData(
        address _mock_account,
        uint256 _mock_shoeId,
        uint256 _mock_steps
    ) public {}
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
