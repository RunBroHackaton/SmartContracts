// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketPlace} from "../Marketplace.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";
import {GetStepsAPI} from "../GSA_V5.sol";

contract Reward {
    IERC20 public immutable i_rbToken;
    MarketPlace public immutable i_marketplace;
    PoolModel2 public immutable i_pool;
    GetStepsAPI public immutable i_getStepsApi;

    uint256 public constant SCALING_FACTOR = 10 ** 3;

    mapping(address => uint256) public s_startingTime;
    // user => time => numberOfSteps till that time
    mapping(address => mapping(uint256 => uint256)) public s_userStepsAtMoment;

    mapping(address => uint256) public s_userSteps;
    mapping(address => uint256) public s_stepShareOfUser;
    uint256 public s_totalStepsByAllUsers;

    constructor(address _rewardToken, address _marketPlace, address _pool, address _getStepsApi) {
        i_getStepsApi = GetStepsAPI(_getStepsApi);
        i_rbToken = IERC20(_rewardToken);
        i_marketplace = MarketPlace(_marketPlace);
        i_pool = PoolModel2(_pool);
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

    function redeemSteps() public {
        
    }

    /**
     * @dev This function will be called by user to retrive his steps.
     */ 
    function sendRequestToFetchSteps() public returns(uint256){
        string[] memory args = new string[](1);
        args[0] = "0";
        i_getStepsApi.sendRequest(args);
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
        uint256 totalStepsByAllUsers = s_totalStepsByAllUsers; 

        s_stepShareOfUser[_account] = (userSteps * i_pool.s_rbReserve() * SCALING_FACTOR)/totalStepsByAllUsers;
        return s_stepShareOfUser[_account];
    }

    // //**IMP - Called By User
    // function claimReward(uint256 _shoeId, uint256 _time, uint256 _steps) public {
    //     require(
    //         i_marketplace.hasPurchasedShoe(msg.sender, _shoeId),
    //         "You are not eligible"
    //     );
    //     // more checks

    //     uint256 reward = _calculateReward(msg.sender, _shoeId, _steps);
    //     _update_startingTime(msg.sender, _time);
    //     i_rbToken.transfer(msg.sender, reward);
    // }

    // //**IMP -
    // function _calculateReward(address _account, uint256 _shoeId, uint256 _steps) internal returns (uint256) {
    //     uint256 rewardOfUser = ((_calculateSharesOfUser(_account, _shoeId) *
    //         i_pool.s_rbReserve()) * i_marketplace.getShoeRB_Factor(_shoeId)) / // To neutralize the scaling factor we need to divide by 1e18.
    //         1e18;
    //     return rewardOfUser;
    // }

    // function _update_startingTime(address _account, uint256 _time) internal {
    //     s_startingTime[_account] = _time;
    // }

    // function _calculateSharesOfUser(
    //     address _account,
    //     uint256 _shoeId
    // ) internal returns (uint256) {
    //     uint256 totalStepsByUser = totalStepsInPeriod_ByUser(_account, _shoeId);
    //     uint256 totalStepsByAllUsers = totalStepsInPeriod_ByAllUsers();
    //     if (totalStepsByAllUsers == 0) {
    //         return 0;
    //     }
    //     uint256 shareOfUser = (totalStepsByUser * SCALING_FACTOR) /
    //         totalStepsByAllUsers;
    //     return shareOfUser;
    // }

    // //--------------------------------------------DANGER-ZONE----------------------------------------------------
    // // All this functions are totally dependent on the retrived value of steps of user.

    // // this function can probably trigger chainlink function to retrieve data.
    // function totalStepsInPeriod_ByUser(
    //     address _account,
    //     uint256 _shoeId
    // ) public returns (uint256) {
    //     s_startingTime[_account] = _registrationTime_InPlatform_ByUser(
    //         _account,
    //         _shoeId
    //     );
    //     return
    //         s_userStepsAtMoment[_account][block.timestamp] -
    //         s_userStepsAtMoment[_account][s_startingTime[_account]];
    // }

    // function _registrationTime_InPlatform_ByUser(
    //     address _account,
    //     uint256 _shoeId
    // ) internal view returns (uint256) {
    //     return i_marketplace.getOrderTime(_account, _shoeId);
    // }

    // // this function can probably trigger chainlink function to retrieve data.
    // function totalStepsInPeriod_ByAllUsers() internal pure returns (uint256) {
    //     // Logic to get steps by all users
    //     return 100000;
    // }

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
