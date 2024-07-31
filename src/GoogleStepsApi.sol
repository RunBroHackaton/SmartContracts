// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {WethRegistry} from "./PoolModels/WethRegistry.sol";

contract GetStepsAPI is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    WethRegistry private immutable wethregistry;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

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

    error UnexpectedRequestID(bytes32 requestId);
    event Response(bytes32 indexed requestId, bytes response, bytes err);
    event DailyStepsDataRecorded(address indexed user,string dataType,uint256 stepsCount );
    event StepsFetched(address indexed user, uint256 stepsCount);

//----CONSTANTS-----------------------------------------------
    address constant router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    uint64 constant subscriptionId = 3004;
    uint32 gasLimit = 300000;
    bytes32 constant donId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

//----Reward related Stuff------------------------------------
    uint256 public s_contractCreationTime;
    mapping(address => mapping(uint256 => bool)) public s_IsUserAlreadyLogin;
    uint256 public s_distributionTimeStamp;
    constructor(address _wethregistry) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        wethregistry = WethRegistry(_wethregistry);
        s_contractCreationTime = block.timestamp;
        s_distributionTimeStamp = getNext6PM(block.timestamp);

    }
    /**
    * @dev rewardDistributionTime is 6 PM Daily. 
    */
    function getNext6PM(uint256 timestamp) public pure returns (uint256) {
        uint256 currentDay = timestamp / 1 days;
        uint256 today6PM = currentDay * 1 days + 18 hours;
        if (timestamp >= today6PM) {
            today6PM += 1 days;
        }
        return today6PM;
    }

    /** 
    * @dev called by automation at 24 hr daily
    */ 
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
    
    /**
     * @dev called by automation at 24 hr daily
     * this will we passed dynamically at source code
     */ 
    function getCurrentDayMidnightTimestamp() public returns (uint256) {
        return _getMidnightTimestamp(block.timestamp);
    }

    /**
     * @dev called by automation at 24 he daily
     * this will we passed dynamically at source code
     */
    function getPreviousDayMidnightTimestamp() public view returns (uint256) {
        // Subtract 1 day (86400 seconds) from the current timestamp
        uint256 previousDayTimestamp = block.timestamp - 1 days;
        return _getMidnightTimestamp(previousDayTimestamp);
    }

    function uintToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + _value % 10));
            _value /= 10;
        }
        return string(buffer);
    }

    function sendRequest(string[] calldata args, string memory authToken) external returns (bytes32 requestId) {

        uint256 startTimeMillis = getPreviousDayMidnightTimestamp() * 1000;
        uint256 endTimeMillis = getCurrentDayMidnightTimestamp() * 1000;

        string memory dynamicSource = string(abi.encodePacked(
            "const accessToken = '", authToken, "';"
            "const stepsRequestBody = {"
            "  aggregateBy: ["
            "    {"
            "      dataTypeName: 'com.google.step_count.delta',"
            "      dataSourceId: 'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',"
            "    },"
            "  ],"
            "  bucketByTime: { durationMillis: 86400000 },"
            "  startTimeMillis: ", uintToString(startTimeMillis), ","
            "  endTimeMillis: ", uintToString(endTimeMillis), ","
            "};"
            "const stepsRequest = await Functions.makeHttpRequest({"
            "  url: 'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',"
            "  method: 'POST',"
            "  headers: {"
            "    Authorization: `Bearer ", authToken, "`,"
            "  },"
            "  data: stepsRequestBody,"
            "});"
            "if (stepsRequest.error) {"
            "  throw new Error(`Request failed with error: ${JSON.stringify(stepsRequest.error)}`);"
            "}"
            "const { data } = stepsRequest;"
            "let totalSteps = 0;"
            "if (data && data.bucket) {"
            "  totalSteps = data.bucket.reduce((total, bucket) => {"
            "    if (bucket.dataset && bucket.dataset.length > 0 && bucket.dataset[0].point && bucket.dataset[0].point.length > 0) {"
            "      return total + bucket.dataset[0].point.reduce((sum, point) => sum + (point.value[0].intVal || 0), 0);"
            "    }"
            "    return total;"
            "  }, 0);"
            "}"
            "return Functions.encodeUint256(totalSteps);"
        ));
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(dynamicSource); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );
        requestIdToAddress[s_lastRequestId] = msg.sender;
        return s_lastRequestId;
    }

    function fulfillRequest(bytes32 requestId,bytes memory response,bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastResponse = response;
        s_lastError = err;

        if(s_lastError.length == 0){
            hasUserFetchedData[requestIdToAddress[requestId]] = true;
        }

        emit Response(requestId, s_lastResponse, s_lastError);

        uint256 stepsCount = abi.decode(response, (uint256));

        if(!hasUserFetchedData[requestIdToAddress[requestId]]){
            totalStepsByAllUsersOnPreviousDay += stepsCount;
        }
        userStepsData[requestIdToAddress[requestId]] = DailyStepsData({
            requester: requestIdToAddress[requestId],
            dataType: "daily_steps",
            stepsCount: stepsCount
        });

        stepsDataRecords.push(
            DailyStepsData({
                requester: requestIdToAddress[requestId],
                dataType: "daily_steps",
                stepsCount: stepsCount
            })
        );

        emit DailyStepsDataRecorded(
            requestIdToAddress[requestId],
            "daily_steps",
            stepsCount
        );
    }

    /**
     * @dev Just a view function
    */
    function getAllDailyStepDataRecords() public view returns (DailyStepsData[] memory){
        return stepsDataRecords;
    }
    
    /**
     * @dev Just a view function
    */
    function func_userStepsData(address _account) public view returns(DailyStepsData memory){
        return userStepsData[_account];
    }

    /**
     *IMP- INCASE IF WE USE APPROACH 1 'DailyStepsData[] public stepsDataRecords'
     *----------------------------------------------------------------
     * @dev This function is supposed to called from fontend side and get the steps data for uinque user, using event 
      'DailyStepsDataRecorded', filtering for a user Address.
     * This is similar to above function, only difference is nameing.
     * on the frontend side the time duration that is 24 hour from 12 AM to 12 AM on next day.
     * on the frontend side the the steps will be recorded.
    */
    function getAllDailyStepDataRecordOf_A_User() public view returns (DailyStepsData[] memory){ 
        return stepsDataRecords;
    }

    /**
     *IMP-INCASE IF WE USE MAPPING APPROACH 2 'mapping(address => DailyStepsData) public userStepsData' along with 
     * ARRAY DailyStepsData[] public stepsDataRecords'
     * @dev This function will give us latest information about user.
    */
    function getLatestUserStepsData(address user) public view returns (DailyStepsData memory) {
        return userStepsData[user];
    }

    /**
     * @dev Just a view function
    */
    function getLastResponse() public view returns (bytes memory) {
        return s_lastResponse;
    }
}
