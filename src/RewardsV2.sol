// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RunBroToken} from "./RunBroToken.sol";
import {Marketplace} from "./Marketplace.sol";
import {RewardToken} from "./RewardToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Reward Contract
 * @author Charles Jones
 * @notice This contract manages a reward system where users earn tokens based on their activity levels.
 *         Users can record their steps, and rewards are calculated and distributed based on these activities.
 *         The contract also supports pausing and unpausing functionalities to control interactions.
 * @dev All function calls are automatically paused when contract is paused.
 */

contract Reward is Ownable, Pausable {
    //errors
    error Reward__StepsMustBeGreaterThanZero();
    error Reward__PurchaseMustBeGreaterThanZero();
    error Reward__InsufficientRewardTokens();
    error Reward__NotYetTimeForMonthlyRewards();
    error Reward__NoStepsRecordedThisMonth();

    // State variables
    RunBroToken public s_runBroToken;
    Marketplace public s_marketplace;
    RewardToken public s_rewardToken;
    uint256 public s_totalSteps;
    uint256 public s_monthlySteps;
    uint256 public s_totalSupplyOfRewardTokens;
    uint256 public s_lastRewardTime;
    uint256 public immutable i_rewardValidityTimeLimit;
    uint256 public constant MONTHLY_REWARD_TOKENS = 10_000;

    //Array to store user addresses
    address[] private users;

    // Mappings to track user and user steps
    mapping(address => bool) private userExists;
    mapping(address => uint256) public s_userSteps;
    mapping(address => uint256) public s_monthlyUserSteps;

    // Events
    event StepsTaken(address indexed user, uint256 steps);
    event MonthlyRewardDistributed(address indexed user, uint256 rewardAmount);
    event PurchaseMade(address indexed user, uint256 rewardAmount);

    // Constructor
    constructor(
        address _runBroTokenAddress,
        address _marketplaceAddress,
        address _rewardTokenAddress,
        uint256 _rewardValidityTimeLimit
    ) Ownable(msg.sender) Pausable() {
        s_runBroToken = RunBroToken(_runBroTokenAddress);
        s_marketplace = Marketplace(_marketplaceAddress);
        s_rewardToken = RewardToken(_rewardTokenAddress);
        s_totalSupplyOfRewardTokens = 10_000_000; // Initial total supply
        s_lastRewardTime = block.timestamp;
        i_rewardValidityTimeLimit = _rewardValidityTimeLimit;
    }

    // Modifier to check if the reward is valid
    modifier isValidReward() {
        require(
            block.timestamp <= s_lastRewardTime + i_rewardValidityTimeLimit,
            "Reward expired"
        );
        _;
    }

    // Function to record steps taken by a user
    function recordSteps(uint256 steps) public whenNotPaused {
        if (steps <= 0) {
            revert Reward__StepsMustBeGreaterThanZero();
        }
        s_userSteps[msg.sender] += steps;
        s_monthlyUserSteps[msg.sender] += steps;
        s_totalSteps += steps;
        s_monthlySteps += steps;
        emit StepsTaken(msg.sender, steps);

        if (!userExists[msg.sender]) {
            users.push(msg.sender);
            userExists[msg.sender] = true;
        }
    }

    // Function to calculate and distribute reward tokens upon purchase
    function calculatePurchaseReward(
        uint256 purchaseAmount
    ) public isValidReward whenNotPaused {
        if (purchaseAmount <= 0) {
            revert Reward__PurchaseMustBeGreaterThanZero();
        }
        uint256 rewardAmount = calculateReward(purchaseAmount);
        s_totalSupplyOfRewardTokens += rewardAmount;
        s_rewardToken.mintRewards(msg.sender, rewardAmount);
        emit PurchaseMade(msg.sender, rewardAmount);
    }

    // Placeholder for calculating reward based on purchase amount
    // This should be adjusted based on your specific reward calculation logic
    function calculateReward(
        uint256 purchaseAmount
    ) public pure returns (uint256) {
        // Example calculation: 10% of purchase amount
        return purchaseAmount / 10;
    }

    // Function to distribute monthly rewards
    function distributeMonthlyRewards() public whenNotPaused onlyOwner {
        if (block.timestamp < s_lastRewardTime + 30 days) {
            revert Reward__NotYetTimeForMonthlyRewards();
        }
        if (s_monthlySteps == 0) {
            revert Reward__NoStepsRecordedThisMonth();
        }

        uint256 totalRewardAmount = 0;
        address[] memory userAddresses = getUsers();

        for (uint i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            uint256 userSteps = s_monthlyUserSteps[user];
            if (userSteps > 0) {
                uint256 rewardAmount = (userSteps * MONTHLY_REWARD_TOKENS) /
                    s_monthlySteps;
                totalRewardAmount += rewardAmount;
            }
        }

        // Check if there are enough reward tokens available
        if (totalRewardAmount > s_totalSupplyOfRewardTokens) {
            revert Reward__InsufficientRewardTokens();
        }

        for (uint i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            uint256 userSteps = s_monthlyUserSteps[user];
            if (userSteps > 0) {
                uint256 rewardAmount = (userSteps * MONTHLY_REWARD_TOKENS) /
                    s_monthlySteps;
                s_rewardToken.mintRewards(user, rewardAmount);
                emit MonthlyRewardDistributed(user, rewardAmount);
            }
            s_monthlyUserSteps[user] = 0; // Reset monthly user steps
        }

        s_monthlySteps = 0; // Reset monthly steps
        s_lastRewardTime = block.timestamp; // Update last reward time
    }

    /**
     * @dev Getter functions for accessing contract state variables.
     * These functions are primarily used by the front end to retrieve
     * user-specific and contract-wide data.
     */

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function getUserSteps(address user) public view returns (uint256) {
        return s_userSteps[user];
    }

    function getTotalSteps() public view returns (uint256) {
        return s_totalSteps;
    }

    function getMonthlyUserSteps(address user) public view returns (uint256) {
        return s_monthlyUserSteps[user];
    }

    function getMonthlySteps() public view returns (uint256) {
        return s_monthlySteps;
    }

    function getRewardValidityTimeLimit() public view returns (uint256) {
        return i_rewardValidityTimeLimit;
    }

    function getTotalSupplyOfRewardTokens() public view returns (uint256) {
        return s_totalSupplyOfRewardTokens;
    }

    function setTotalSupplyOfRewardTokens(uint256 newSupply) public onlyOwner {
        s_totalSupplyOfRewardTokens = newSupply;
    }

    // Owner-only function to set a new marketplace address
    function setMarketplaceAddress(
        address _marketplaceAddress
    ) public onlyOwner {
        s_marketplace = Marketplace(_marketplaceAddress);
    }

    // Emergency stop functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
