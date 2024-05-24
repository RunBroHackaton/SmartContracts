// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RunBroToken} from "./RunBroToken.sol";
import {Marketplace} from "./Marketplace.sol";
import {RewardToken} from "./RewardToken.sol";

contract Reward {
    // State variables
    RunBroToken public s_runBroToken;
    Marketplace public s_marketplace;
    RewardToken public s_rewardToken;
    uint256 public s_totalSteps;
    uint256 public immutable i_rewardValidityTimeLimit;
    uint256 public immutable i_totalSupplyOfRewardTokens;

    // Mapping to track user steps
    mapping(address => uint256) public s_userSteps;

    // Events
    event StepsTaken(address indexed user, uint256 steps);
    event PurchaseMade(address indexed user, uint256 rewardAmount);
    event AffiliateMarketing(
        address indexed referrer,
        address indexed referred,
        uint256 rewardAmount
    );

    // Constructor
    constructor(
        address _runBroTokenAddress,
        address _marketplaceAddress,
        address _rewardTokenAddress,
        uint256 _rewardValidityTimeLimit
    ) {
        s_runBroToken = RunBroToken(_runBroTokenAddress);
        s_marketplace = Marketplace(_marketplaceAddress);
        s_rewardToken = RewardToken(_rewardTokenAddress);
        i_rewardValidityTimeLimit = _rewardValidityTimeLimit;
        i_totalSupplyOfRewardTokens = 0;
    }

    // Modifier to check if the reward is valid
    modifier isValidReward() {
        require(
            block.timestamp <=
                i_totalSupplyOfRewardTokens + i_rewardValidityTimeLimit,
            "Reward expired"
        );
        _;
    }

    // Function to record steps taken by a user
    function recordSteps(uint256 steps) public {
        s_userSteps[msg.sender] += steps;
        s_totalSteps += steps;
        emit StepsTaken(msg.sender, steps);
    }

    // Function to calculate and distribute reward tokens upon purchase
    function calculatePurchaseReward(
        uint256 purchaseAmount
    ) public isValidReward {
        uint256 rewardAmount = calculateReward(purchaseAmount);
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

    /**
     * @dev just an idea for us to use affiliate marketing
     * can be commented out until needed
     * Function to handle affiliate marketing rewards
     * This is a placeholder and should be expanded based on your affiliate program specifics
     */
    function handleAffiliateMarketing(
        address referrer,
        address referred
    ) public isValidReward {
        uint256 rewardAmount = calculateAffiliateReward(referrer, referred);
        s_rewardToken.mintRewards(referred, rewardAmount);
        emit AffiliateMarketing(referrer, referred, rewardAmount);
    }

    /**
     * @dev just an idea for us to use affiliate marketing
     * can be commented out until needed
     * Placeholder for calculating affiliate reward
     * This should be adjusted based on specific affiliate program logic
     * */
    function calculateAffiliateReward(
        address referrer,
        address referred
    ) public pure returns (uint256) {
        // Example calculation: $5 per referral
        return 5 ether;
    }

    // Getter functions
    function getUserSteps(address user) public view returns (uint256) {
        return s_userSteps[user];
    }

    function getTotalSteps() public view returns (uint256) {
        return s_totalSteps;
    }

    function getRewardValidityTimeLimit() public view returns (uint256) {
        return i_rewardValidityTimeLimit;
    }

    function getTotalSupplyOfRewardTokens() public view returns (uint256) {
        return i_totalSupplyOfRewardTokens;
    }
}
