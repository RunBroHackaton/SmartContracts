// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketPlace} from "../Marketplace.sol";
import {PoolModel2} from "../PoolModels/PoolModel2.sol";

contract Reward {
    IERC20 public immutable i_rbToken;
    MarketPlace public immutable i_marketplace;
    PoolModel2 public immutable pool;

    uint256 public constant SCALING_FACTOR = 10 ** 18;

    mapping(address => uint256) public s_startingTime;
    // user => time => numberOfSteps till that time
    mapping(address => mapping(uint256 => uint256)) public s_userStepsAtMoment;

    constructor(address _rewardToken, address _marketPlace, address _pool) {
        i_rbToken = IERC20(_rewardToken);
        i_marketplace = MarketPlace(_marketPlace);
        pool = PoolModel2(_pool);
    }

    //**IMP - Called By User
    function swaprbToken() public {
        require(
            i_rbToken.balanceOf(msg.sender) > 0,
            "You don't have suffient RB Tokens"
        );
        pool.swap(address(i_rbToken), i_rbToken.balanceOf(msg.sender));
    }

    //**IMP - Called By User
    function claimReward(uint256 _shoeId) public {
        require(
            i_marketplace.hasPurchasedShoe(msg.sender, _shoeId),
            "You are not eligible"
        );
        // more checks

        uint256 reward = calculateReward(msg.sender, _shoeId);
        _update_startingTime(msg.sender);
        i_rbToken.transfer(msg.sender, reward);
    }

    //**IMP - Called By User
    function calculateReward(
        address _account,
        uint256 _shoeId
    ) public returns (uint256) {
        uint256 rewardOfUser = ((calculateSharesOfUser(_account, _shoeId) *
            pool.s_rbReserve()) * i_marketplace.getShoeRB_Factor(_shoeId)) / // To neutralize the scaling factor we need to divide by 1e18.
            1e18;
        return rewardOfUser;
    }

    function _update_startingTime(address _account) internal {
        s_startingTime[_account] = block.timestamp;
    }

    function calculateSharesOfUser(
        address _account,
        uint256 _shoeId
    ) public returns (uint256) {
        uint256 totalStepsByUser = totalStepsInPeriod_ByUser(_account, _shoeId);
        uint256 totalStepsByAllUsers = totalStepsInPeriod_ByAllUsers();
        if (totalStepsByAllUsers == 0) {
            return 0;
        }
        uint256 shareOfUser = (totalStepsByUser * SCALING_FACTOR) /
            totalStepsByAllUsers;
        return shareOfUser;
    }

    //--------------------------------------------DANGER-ZONE----------------------------------------------------
    // All this functions are totally dependent on the retrived value of steps of user.

    // this function can probably trigger chainlink function to retrieve data.
    function totalStepsInPeriod_ByUser(
        address _account,
        uint256 _shoeId
    ) public returns (uint256) {
        s_startingTime[_account] = _registrationTime_InPlatform_ByUser(
            _account,
            _shoeId
        );
        return
            s_userStepsAtMoment[_account][block.timestamp] -
            s_userStepsAtMoment[_account][s_startingTime[_account]];
    }

    function _registrationTime_InPlatform_ByUser(
        address _account,
        uint256 _shoeId
    ) internal view returns (uint256) {
        return i_marketplace.getOrderTime(_account, _shoeId);
    }

    // this function can probably trigger chainlink function to retrieve data.
    function totalStepsInPeriod_ByAllUsers() internal pure returns (uint256) {
        // Logic to get steps by all users
        return 100000;
    }

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
