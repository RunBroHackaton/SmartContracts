// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract GetStepsAPI is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    struct DailyStepsData {
        address requester;
        string dataType;
        uint256 startTime;
        uint256 endTime;
        uint256 stepsCount;
    }

    mapping(address => DailyStepsData) public userStepsData; // Mapping to store steps data for each user
    mapping(bytes32=> address) public requestIdToAddress;

    DailyStepsData[] public stepsDataRecords;

    uint256 public totalStepsByAllUsersOnPreviousDay;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);
    event DailyStepsDataRecorded(
        address indexed user,
        string dataType,
        uint256 startTime,
        uint256 endTime,
        uint256 stepsCount
    );

    /**
     * CUSTOM PARAMS - START
     *
     * @dev FunctionsClient takes router as parameter
     *      Below is set for Sepolia
     * Additional Routers can be found at
     *      https://docs.chain.link/chainlink-functions/supported-networks
     */
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    uint64 subscriptionId = 2976; //Chainlink Functions Subscription ID
    //uint64 subscriptionId = 2934; //Chainlink Functions Subscription ID

    uint32 gasLimit = 300000; //Gas limit for callback tx do not change
    bytes32 donId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // CUSTOM PARAMS - END
    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * @dev To update subscription id
     */
    function updateSubscriptionId(uint64 _id) public {
        subscriptionId = _id;
    }

    /**
     * @dev This will probably called by chainlink automation at 24 hours
     */
    function updateUserStepsData(address _account) public {
        if(block.timestamp >= userStepsData[_account].endTime){
            userStepsData[_account].stepsCount = 0; 
        }
    }

    /**
     * @dev This will probably called by chainlink automation at 24 hours
     */
    function updateAllUsersSteps(uint256 _time) public {
        totalStepsByAllUsersOnPreviousDay = 0;
    }

    /**
     * Example JavaScript to interact with Google Fit API
     * @dev Note: This assumes an access token is available and passed to the script
     * @param accessToken: should coincide with JavaScript on front end
     * @dev _startTime and _endTime may be supplied from frontend side.
    */
    function sendRequest(string memory accessToken, uint256 _startTime, uint256 _endtime) external onlyOwner returns (bytes32 requestId) {
        string memory sourceWithToken = string(
            abi.encodePacked(
                "const accessToken = '",
                accessToken,
                "'; const url = `https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate?access_token=",
                accessToken,
                "`; const newRequest = Functions.makeHttpRequest({ url, headers: { 'Authorization': `Bearer ",
                accessToken,
                "` } }); const newResponse = await newRequest; if (newResponse.error) { throw Error(`Error fetching fitness data`);} return Functions.encodeString(JSON.stringify(newResponse.data));"
            )
        );

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(sourceWithToken);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );

        requestIdToAddress[s_lastRequestId] = msg.sender;
        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastResponse = response;
        s_lastError = err;
        emit Response(requestId, s_lastResponse, s_lastError);

        uint256 stepsCount = abi.decode(response, (uint256));
        totalStepsByAllUsersOnPreviousDay += stepsCount;

    // Approach 1
        userStepsData[requestIdToAddress[requestId]] = DailyStepsData({
            requester: requestIdToAddress[requestId],
            dataType: "daily_steps",
            startTime: block.timestamp,
            endTime: block.timestamp + 24 hours,
            stepsCount: stepsCount
        });
    // Approach 2
        stepsDataRecords.push(
            DailyStepsData({
                requester: requestIdToAddress[requestId],
                dataType: "daily_steps",
                startTime: block.timestamp - 24 hours, // this can be different, if startTime depends on frontend 
                endTime: block.timestamp, // this can be different, if endTime depends on frontend 
                stepsCount: stepsCount
            })
        );
    // We will use either of 2 Approachs.

        emit DailyStepsDataRecorded(
            requestIdToAddress[requestId],
            "daily_steps",
            block.timestamp - 24 hours,
            block.timestamp,
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
