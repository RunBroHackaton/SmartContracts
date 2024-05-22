// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
contract Proxy {
    mapping (address => uint) rewardEarnedByUser;
    address public implementation;
    address public admin;
   

    constructor() {
        admin = msg.sender;
    }

    function getRewardEarnedByUser() public view returns(uint256){
        return rewardEarnedByUser[msg.sender];
    }

    function _delegate() private {
        (bool ok, ) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
    // User interface //
    function _delegate(address _implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function upgradeTo(address _implementation) external {
        require(msg.sender == admin, "not authorized");
        implementation = _implementation;
    }
}
