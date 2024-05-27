//----------------------------------NOT IN USE---------------------------------------
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Reward {
    mapping (address => uint) rewardEarnedByUser;
    IERC20 public immutable rewardsToken;
    // User Address => Steps by user
    mapping (address => uint) public userSteps;
    // Check weather user has purchased the shoes or not?
    mapping (address => bool) public isUserPurchasedAnyShoe;

    address public owner;
    // Minimum number of steps required by a user
    uint public minimumStepsRequired = 10_000;
    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total Steps)
    uint public rewardPerStepStored;
     // User address => rewardPerStepStored
    mapping (address => uint) public userRewardPerStepPaid;
    // User address => rewards to be claimed
    mapping (address => uint) public rewards;
    // User address => ShoeId => RB Factor
    mapping (address => mapping (bytes8 => uint8)) public RB_Factor_Of_ShoeIdOwnedByUser;
    // Total steps
    uint public totalSteps;
    // User address => staked amount
    mapping(address => uint) public balanceOf;
    // User address => bool
    mapping(address => bool) public has_Staked;


    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerStepStored = rewardPerStep();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerStepPaid[_account] = rewardPerStepStored;
        }

        _;
    }

    modifier mustPurchaseAShoe(){
        require(isUserPurchasedAnyShoe[msg.sender],"Must purchase a Shoe");
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function setSteps(uint steps) public {
        userSteps[msg.sender]+=steps;
        totalSteps+=steps;
    }
    function getSteps() public view returns (uint256){
        return userSteps[msg.sender];
    }

    function rewardPerStep() public view returns (uint) {
        if (totalSteps == 0) {
            return rewardPerStepStored;
        }

        return
            rewardPerStepStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSteps;
    }

    function stakeTheSteps() external updateReward(msg.sender) mustPurchaseAShoe{
        require(userSteps[msg.sender]>= minimumStepsRequired, "step count is less than 10_000");
        has_Staked[msg.sender] = true;
        totalSteps += userSteps[msg.sender]; // balanceOf[msg.sender] += _amount;
    }

    function earned(address _account) public returns (uint) {
        require(has_Staked[_account] , "user");
        rewardEarnedByUser[_account] = (((userSteps[_account])*
            (rewardPerStep() - userRewardPerStepPaid[_account])) / 1e18) +
        rewards[_account];
        return rewardEarnedByUser[_account];
        
        // return
        //     (((userSteps[_account] * RB_Factor_Of_ShoeIdOwnedByUser[msg.sender][bytes8("1")])*
        //         (rewardPerStep() - userRewardPerStepPaid[_account])) / 1e18) +
        //     rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
