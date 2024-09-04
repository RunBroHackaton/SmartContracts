// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {RunBroToken} from "../RunBroToken.sol";
import {MarketPlace} from "../Marketplace.sol";
import {GetStepsAPI} from "../GoogleStepsApi.sol";
import {WethRegistry} from "../PoolModels/WethRegistry.sol";
import {WethReward} from "../RewardModels/WethRewardModel.sol";
import {Escrow} from "../Escrow.sol";

// DAO imports
import {KYC} from "../DAO-KYC.sol";
interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address s_owner) external view returns (uint);

    function allowance(
        address s_owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);
}

contract DeployContracts is Script {
    address public constant wethAddress = 0x48f7D56c057F20668cdbaD0a9Cd6092B3dc83684; // On Sepolia
    // address public constant wethAddress = 0x52eF3d68BaB452a294342DC3e5f464d7f610f72E; // On Amoy
    uint256 public initialSupply = 1000000 * 10 ** 18;
    uint256 public initial_rbTokens_inPool = 10000 * 10 ** 18;
    uint256 public initial_weth_inPool = 10000 * 10 ** 18;

    address public seller = address(1);
    address public buyer = address(2);

    address public owner;

    //--------------------------------------------TESTING PURPOSE---------------------------------------------------------

    address[] public usersABC;
    uint256[] public users123;
    function createRandomUsers(uint256 count) internal {
        usersABC.push(0x345F30Cea2EF88227C2D301302E17900E1FcDA06);
        for (uint256 i = 0; i < count; i++) {
            usersABC.push(address(uint160(uint256(keccak256(abi.encodePacked(i, block.timestamp))))));
        }
    }

    function createRandomrbfs(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            users123.push(10*(i+1));
        }
    }
    //--------------------------------------------TESTING PURPOSE---------------------------------------------------------
    function run() external {
        owner = msg.sender;
        vm.startBroadcast(owner);

        RunBroToken rbToken = new RunBroToken(initialSupply);
        Escrow escrow = new Escrow();

        WethRegistry wethRegistry = new WethRegistry();
        KYC kyc = new KYC(address(rbToken));
        MarketPlace marketPlace = new MarketPlace(address(wethRegistry), wethAddress, payable(address(escrow)), address(rbToken), address(kyc));
        wethRegistry._loadMarketPlace(address(marketPlace));
        GetStepsAPI getstepsapi = new GetStepsAPI(address(wethRegistry));
        WethReward wethReward = new WethReward(wethAddress, address(marketPlace), payable(address(wethRegistry)), address(getstepsapi));
        wethRegistry._doApprovalToWethReward(wethAddress, address(wethReward));

    //----------------------------------------------TESTING PURPOSE-------------------------------------------------------
        // createRandomUsers(99);
        // createRandomrbfs(100);
        // wethRegistry.setRandomSlotData(0, 100, usersABC, users123, 60000000000,40000000);

        // wethRegistry.distributeBalanceToSlot();
    //----------------------------------------------TESTING PURPOSE-------------------------------------------------------
        vm.stopBroadcast();

        console.log("RB Token Address", address(rbToken));
        console.log("WethRegistry Address", address(wethRegistry));
        console.log("MarketPlace Address", address(marketPlace));
        console.log("GetStepsApi Address", address(getstepsapi));
        console.log("WethReward Address", address(wethReward));
        console.log("KYC Address", address(kyc));
    }
}

