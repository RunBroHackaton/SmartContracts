// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*@dev
 The purpose of this contract to bring all the external functions in different contracts at one place,
 so frontend only need to interact with this contract instead of 4 diff contracts.
*/

interface IReward {
    function swaprbToken() external;

    function claimReward(uint256 _shoeId) external;

    function calculateReward( address _account, uint256 _shoeId) external returns(uint256);
    
}

interface IPool {
    // called by owner
    function setIntialBalanceOfpool(uint256 _amount) external;
    // called by owner and chainlink automation.
    function addLiquidity() external;
}

interface IMarketPlace {

    function mapEmailToSteps(string calldata _email, uint256 _steps) external;

    function mapEmailToAddress(string calldata _email, address _account) external;

    function linkAddressToSteps(string calldata _email, address _account) external;

    function list(
        uint256 _id,
        string memory _name,
        string memory _brand,
        string memory _image,
        uint256 _cost,
        uint256 _RB_Factor,
        uint256 _quantity
    ) external  payable;

    function buy(uint256 _id) external payable; 
}

interface IRunBro {


}

contract Interaction {

    IReward public immutable i_reward;
    IPool public immutable i_pool;
    IRunBro public immutable i_runbro;
    IMarketPlace public immutable i_marketplace;

    constructor(address _reward, address _pool, address _runbro, address _marketplace){
        i_reward = IReward(_reward);
        i_pool = IPool(_pool);
        i_runbro = IRunBro(_runbro);
        i_marketplace =IMarketPlace(_marketplace);
    }
//-----------------------------MarketaPlace functions--------------------------------------------
//     function list(uint256 _id, string memory _name, string memory _brand, string memory _image, uint256 _cost, uint256 _RB_Factor, uint256 _quantity) public{
//         i_marketplace.list(_id, _name, _brand, _image, _cost, _RB_Factor, _quantity);
//     }

//     function buy(uint256 _id) public{
//         i_marketplace.buy(_id);
//     }   

//     function mapEmailToAddress(string calldata _email, address _account) public {
//         i_marketplace.mapEmailToAddress(_email, _account);
//     }

//     function mapEmailToSteps(string calldata _email, uint256 _steps) public {
//         i_marketplace.mapEmailToSteps(_email, _steps);
//     }

//     function linkAddressToSteps(string calldata _email, address _account) public {
//         i_marketplace.linkAddressToSteps(_email, _account);
//     }
// //---------------------------Pool functions-------------------------------------------
//    // called by chainlink automation every 24 hour.

//     function setInitailPoolBalance() public {
//         i_pool.setIntialBalanceOfpool();
//     }

//     function addLiquidity() public {
//         i_pool.addLiquidity();
//     }

// //--------------------------Reward Functions------------------------------------------

//     function swap() public {
//         i_reward.swaprbToken();
//     }

//     function claimReward(uint256 _shoeId) public{
//         i_reward.claimReward();
//     }

//     function calculateReward( address _account, uint256 _shoeId) external returns(uint256);


}