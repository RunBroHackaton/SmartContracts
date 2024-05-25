// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketPlace} from "../MarketPlace.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";

contract StepRewardToken{
    IERC20 public immutable rewardsToken;
    MarketPlace public immutable marketplace;
    PoolModel2 public immutable pool;

    uint256 public constant SCALING_FACTOR = 10**18;
    
    mapping (address => uint256) public startingTime;
    // user => time => numberOfSteps till that time
    mapping (address => mapping (uint256 => uint256)) public userStepsAtMoment;

    constructor(address _rewardToken, address _marketPlace, address _pool){
        rewardsToken = IERC20(_rewardToken);
        marketplace = MarketPlace(_marketPlace);
        pool = PoolModel2(_pool);
    }

    function claimReward(uint256 _shoeId) public {
        require(marketplace.hasPurchasedShoe(msg.sender,_shoeId),"You are not eligible");
        // more checks
    
        uint256 reward = calculateReward(msg.sender, _shoeId);
        _update_startingTime(msg.sender);
        rewardsToken.transfer(msg.sender, reward);
    }

    function calculateReward(address _account, uint256 _shoeId) public returns(uint256){
        uint256 rewardOfUser = ((calculateSharesOfUser(_account, _shoeId)*pool.reserve1()) // To neutralize the scaling factor we need to divide by 1e18.
                               *marketplace.getShoeRB_Factor(_shoeId))/1e18;
        return rewardOfUser;
    }

    function _update_startingTime(address _account) internal{
        startingTime[_account]= block.timestamp;
    }

    function calculateSharesOfUser(address _account, uint256 _shoeId) public returns(uint256){
        uint256 totalStepsByUser = totalStepsInPeriod_ByUser(_account, _shoeId);
        uint256 totalStepsByAllUsers = totalStepsInPeriod_ByAllUsers();
        if (totalStepsByAllUsers == 0) {
            return 0;
        }
        uint256 shareOfUser = (totalStepsByUser * SCALING_FACTOR) / totalStepsByAllUsers;
        return shareOfUser;
    }
 
    function _registrationTime_InPlatform_ByUser(address _account, uint256 _shoeId) internal view returns (uint256) {
        return marketplace.getOrderTime(_account, _shoeId);
    }

    function totalStepsInPeriod_ByUser(address _account, uint256 _shoeId) public returns (uint256){
        startingTime[_account] = _registrationTime_InPlatform_ByUser(_account, _shoeId);
        return userStepsAtMoment[_account][block.timestamp]-
        userStepsAtMoment[_account][startingTime[_account]];
    }

    function totalStepsInPeriod_ByAllUsers() internal pure returns (uint256) {
        return 100000; 
    }
}

interface IERC20 {
        function totalSupply() external view returns (uint);

        function balanceOf(address account) external view returns (uint);

        function transfer(address recipient, uint amount) external returns (bool);

        function allowance(address owner, address spender) external view returns (uint);

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
