// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract Registration is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    enum MintOrRedeem{
        mint,
        redeem
    }

    struct Gfit_Steps_Request{
        string googletokenauth;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

    address constant AMOY_FUNCTION_ROUTER = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;
    bytes32 constant DON_ID = hex"66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000";
    uint32 constant GAS_LIMIT=300_000;
    uint64 immutable subscriptionId;

    string private s_StepsApiSourceCode;
    uint256 private s_usersteps;
    mapping(bytes32 requestId => Gfit_Steps_Request request) private s_requestIdToRequest;

    constructor(string memory _apiSourceCode, uint64 _subscriptionId) FunctionsClient(AMOY_FUNCTION_ROUTER){
        s_StepsApiSourceCode = _apiSourceCode;
        subscriptionId = _subscriptionId;
    }

    function sendStepsRequest(string memory _googletokenauth) external returns(bytes32){
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_StepsApiSourceCode);
        bytes32 requestId = _sendRequest(req.encodeCBOR(), subscriptionId, GAS_LIMIT, DON_ID);
        s_requestIdToRequest[requestId] = Gfit_Steps_Request(_googletokenauth, msg.sender, MintOrRedeem.mint);
        return requestId;
    }

    // Retern the number of steps by user;
    function _stepsFulFillRequest(bytes32 requestId, bytes memory response) internal{
        string memory userGoogleTokenAuth = "";
        s_usersteps = uint256(bytes32(response));
    }

    function fulfillRequest(bytes32 requetsId, bytes memory response, bytes memory /*err*/) external override {
        if(s_requestIdToRequest[requetsId].mintOrRedeem == MintOrRedeem.mint){
            _stepsFulFillRequest(requetsId, response);
        }
    }
}