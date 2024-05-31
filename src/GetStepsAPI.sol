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
        string dataType;
        uint256 startTime;
        uint256 endTime;
        uint256 stepsCount;
    }

    DailyStepsData[] private stepsDataRecords;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);
    event DailyStepsDataRecorded(
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
    uint64 subscriptionId = 2934; //Chainlink Functions Subscription ID
    uint32 gasLimit = 300000; //Gas limit for callback tx do not change
    bytes32 donId =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // CUSTOM PARAMS - END

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * Example JavaScript to interact with Google Fit API
    // @dev Note: This assumes an access token is available and passed to the script
     * @param accessToken: should coincide with JavaScript on front end
     */

    function sendRequest(
        string memory accessToken
    ) external onlyOwner returns (bytes32 requestId) {
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

        // Assuming the response is a formatted string or encoded data representing daily steps
        // Decode or parse the response here according to its format
        // For simplicity, let's assume it's a simple string representation of steps count
        uint256 stepsCount = uint256(keccak256(abi.encodePacked(response))); // Simplified conversion for illustration

        // Store the parsed data
        stepsDataRecords.push(
            DailyStepsData({
                dataType: "daily_steps",
                startTime: block.timestamp,
                endTime: block.timestamp + 24 hours, // Assuming daily steps cover a full day
                stepsCount: stepsCount
            })
        );

        emit DailyStepsDataRecorded(
            "daily_steps",
            block.timestamp,
            block.timestamp + 24 hours,
            stepsCount
        );
    }

    function getAllDailyStepDataRecords()
        public
        view
        returns (DailyStepsData[] memory)
    {
        return stepsDataRecords;
    }

    function getLastResponse() public view returns (bytes memory) {
        return s_lastResponse;
    }
}
