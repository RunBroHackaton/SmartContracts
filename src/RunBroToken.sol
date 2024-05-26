// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
//0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev ERC downloaded from OpenZeppelin Contracts
 * all functions are available
 */

contract RunBroToken is ERC20, Ownable {
    constructor(uint256 initialSupply) Ownable(msg.sender) ERC20("RunBroToken", "RBT")  {
        _mint(msg.sender, initialSupply);
    }

    function mint(address _address, uint256 _amount) external onlyOwner{
        _mint(_address, _amount);
    }

    function mintRewards(address account, uint256 amount) external onlyOwner {
        super._mint(account, amount);
    }

    function safeTransfer(address to, uint256 amount) external onlyOwner {
        super.transfer(to, amount);
    }
}