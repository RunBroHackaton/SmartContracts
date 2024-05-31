// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {GSA_V2} from "../GSA_V2.sol";

contract DeployGFit is Script{

    string public constant fitSource = "./functions/sources/gFitSteps.js";

    function run() external{
        string memory _fitSource = vm.readFile(fitSource);
        vm.startBroadcast();
        GSA_V2 gsa = new GSA_V2();
        
    }
}