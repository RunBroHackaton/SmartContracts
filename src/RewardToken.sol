// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20, Ownable {
    error RewardToken__OnlyOwnerCanMint();

    constructor(
        uint256 initialSupply
    ) ERC20("RewardToken", "RT") Ownable(msg.sender) {
        // Additional constructor logic if needed
    }

    function mintRewards(address account, uint256 amount) external {
        if (msg.sender != owner()) {
            revert RewardToken__OnlyOwnerCanMint();
        }
        super._mint(account, amount);
    }
}
