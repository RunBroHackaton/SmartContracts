// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev ERC downloaded from OpenZeppelin Contracts
 * all functions are available
 */

contract RunBroToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("RunBroToken", "RBT") {
        _mint(msg.sender, initialSupply);
    }
}
