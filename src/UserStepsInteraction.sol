// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
//-----------------------------------------------------IGNORE THIS FOR NOW--------------------------------------------------------------
import {GetStepsAPI} from "./GetStepsAPI.sol";

contract UserStepsData {
   GetStepsAPI public getStepsAPI;

   mapping(address => uint256) public userStepsOnPreviousDay;

   constructor(address _getStepsAPI) {
    getStepsAPI = GetStepsAPI(_getStepsAPI);
   }

   function userIneraction() public {
      //   GetStepsAPI.DailyStepsData memory latestData = getStepsAPI.getLatestDailyStepData();
      //   userStepsOnPreviousDay[msg.sender] = latestData.stepsCount;
   }

}