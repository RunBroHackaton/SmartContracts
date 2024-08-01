// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {WethRegistry} from "src/PoolModels/WethRegistry.sol";

contract MockGoogleStepsAPI{

    struct DailyStepsData {
        address requester;
        string dataType;
        uint256 stepsCount;
    }

    DailyStepsData[] public stepsDataRecords;
    mapping(address => DailyStepsData) public userStepsData; // Mapping to store steps data for each user
    mapping(bytes32=> address) public requestIdToAddress;
    mapping(address=> bool) public hasUserFetchedData; 

    uint256 public totalStepsByAllUsersOnPreviousDay;
    mapping(uint256 => mapping(address => uint256)) public totalStepsByAllUsersInSlotOnPreviousDay; // slot => (user => steps)


    uint256 public s_contractCreationTime;
    mapping(address => mapping(uint256 => bool)) public s_IsUserAlreadyLogin;
    uint256 public s_distributionTimeStamp;

    WethRegistry public wethregistry;
    mapping(address => bool) public s_userSendRequest;


    constructor(address _wethregistry) {
        wethregistry = WethRegistry(_wethregistry);
        s_contractCreationTime = block.timestamp;
        s_distributionTimeStamp = getNext6PM(block.timestamp);
    }
    function getNext6PM(uint256 timestamp) public pure returns (uint256) {
        uint256 currentDay = timestamp / 1 days;
        uint256 today6PM = currentDay * 1 days + 18 hours;
        if (timestamp >= today6PM) {
            today6PM += 1 days;
        }
        return today6PM;
    }

    function updateRewardDistributionTime() public {
        require(block.timestamp >= s_distributionTimeStamp, "It's not time yet");
        /** 
        * @dev Reseting user steps data to initial value, if this function is called.
        */ 
        for (uint256 i = 0; i < stepsDataRecords.length; i++) {
                address user = stepsDataRecords[i].requester;
                delete userStepsData[user];
                hasUserFetchedData[user] = false;
        }
        delete stepsDataRecords;

        // Reset total steps count
        totalStepsByAllUsersOnPreviousDay = 0;
        s_distributionTimeStamp += 1 days;
    }

    function _getMidnightTimestamp(uint256 timestamp) internal pure returns (uint256) {
        uint256 currentDay = timestamp / 1 days;
        uint256 midnightTimestamp = currentDay * 1 days;
        return midnightTimestamp;
    }

    function getCurrentDayMidnightTimestamp() public returns (uint256) {
        return _getMidnightTimestamp(block.timestamp);
    }

    function getPreviousDayMidnightTimestamp() public view returns (uint256) {
        // Subtract 1 day (86400 seconds) from the current timestamp
        uint256 previousDayTimestamp = block.timestamp - 1 days;
        return _getMidnightTimestamp(previousDayTimestamp);
    }
    function _setMockData(address _user, uint256 _steps) internal {
        userStepsData[_user] = DailyStepsData(_user, "daily_steps", _steps);
    }
    function sendRequest(string[] calldata args, string memory authToken) public returns(bytes32 requestId){
        s_userSendRequest[msg.sender] = true;
        requestId = bytes32(uint256(uint160(address(msg.sender))));
        bytes memory response = bytes("addd");
        bytes memory err = bytes("addd");
        fullfillRequest(requestId, response, err);
    }
    function fullfillRequest(bytes32 requestId, bytes memory response, bytes memory err) public{
        require(s_userSendRequest[_account] == true, "User not requested");
        _setMockData(_account,_steps);
        s_userSendRequest[msg.sender] = false;
    }

    function getLatestUserStepsData(address _user) public view returns(DailyStepsData memory){
        return userStepsData[_user];
    }

    // function sendRequest(string[] memory _args, string memory _authToken) public returns(bytes32){
    //     bytes32 requestId = keccak256(abi.encodePacked(_args, _authToken));
    //     requestIdToAddress[requestId] = msg.sender;
    //     return requestId;
    // }

    // function fulfillRequest(bytes32 _requestId, bytes memory _response, bytes memory _error) public {
    //     uint256 stepsCount = abi.decode(_response, (uint256));
    //     userStepsData[msg.sender] = DailyStepsData(stepsCount, msg.sender, "daily_steps");
    //     totalStepsByAllUsersOnPreviousDay = stepsCount;
    // }
}