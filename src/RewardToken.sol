// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//************************************** **********************/
/**
 * @dev to be used at a later time
 */
//*************************************** *********************/

// contract RewardToken is ERC20, Ownable {
//     error RewardToken__OnlyOwnerCanMint();

//     constructor(
//         uint256 initialSupply
//     ) ERC20("RewardToken", "RT") Ownable(msg.sender) {
//         _mint(msg.sender, initialSupply);
//     }

//     function mintRewards(address account, uint256 amount) external onlyOwner {
//         super._mint(account, amount);
//     }

//     function safeTransfer(address to, uint256 amount) external onlyOwner {
//         super.transfer(to, amount);
//     }
// }
