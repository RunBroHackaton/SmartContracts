// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketPlace} from "../Marketplace.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {GetStepsAPI} from "../GSA_V6.sol";
import {WethRegistry} from "../PoolModels/WethRegistry.sol";

contract WethReward {
    MarketPlace public immutable i_marketplace;
    GetStepsAPI public immutable i_getStepsApi;
    WethRegistry public immutable i_wethRegistry;

    uint256 public constant SCALING_FACTOR = 10 ** 3;

    mapping(address => uint256) public s_startingTime;
    // user => time => numberOfSteps till that time
    mapping(address => mapping(uint256 => uint256)) public s_userStepsAtMoment;

    mapping(address => uint256) public s_userSteps;
    mapping(address => uint256) public s_stepShareOfUser;
    uint256 public s_totalStepsByAllUsersInSlot;

    constructor(address _rewardToken, address _marketPlace, address _wethRegistry, address _getStepsApi) {
        i_getStepsApi = GetStepsAPI(_getStepsApi);
        i_marketplace = MarketPlace(_marketPlace);
        i_wethRegistry = WethRegistry(_wethRegistry);
    }

    /**
     * @dev This function will be called by user to convert rbToken to weth.
     */ 
    function swaprbToken() public {
        require(
            i_rbToken.balanceOf(msg.sender) > 0,
            "You don't have suffient RB Tokens"
        );
        i_pool.swap(address(i_rbToken), i_rbToken.balanceOf(msg.sender));
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
        s_userSteps[msg.sender] = userStepsDailyData.stepsCount;
        s_totalStepsByAllUsers = i_getStepsApi.totalStepsByAllUsersOnPreviousDay();
    }

    /**
     * @dev this function will only be called by user to claim his reward.
     */ 

    function takeRewardBasedOnShoeId(uint256 _shoeId) public{
        require(i_marketplace.checkUserRegistraction(msg.sender),"User not registered");
        require(i_marketplace.hasPurchasedShoe(msg.sender, _shoeId),"You are not eligible");

        uint256 rewardAmount = _calculateRewardOfUserSteps(msg.sender, _shoeId);

        i_rbToken.transferFrom(address(i_pool), msg.sender, rewardAmount);
    }

    function _calculateRewardOfUserSteps(address _account, uint256 _shoeId) internal returns(uint256){
        uint256 RB_Factor = i_marketplace.getShoeRB_Factor(_shoeId);
        uint256 rewardOfUser = _calculateShareOfUsersSteps(_account) * RB_Factor ;
        return rewardOfUser;
    }

    function _calculateShareOfUsersSteps(address _account) internal returns(uint256){
        uint256 userSteps = s_userSteps[_account];
        uint256 totalStepsByAllUsers = s_totalStepsByAllUsersInSlot;
        
        s_stepShareOfUser[_account] = (userSteps * i_pool.s_rbReserve() * SCALING_FACTOR)/totalStepsByAllUsers;
        return s_stepShareOfUser[_account];
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
