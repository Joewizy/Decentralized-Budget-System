// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; //

import {Script, console} from "forge-std/Script.sol";
import {BudgetSystem} from "../src/BudgetSystem.sol";

contract DeployBudgetSystem is Script {
    uint256 private constant TOTAL_BUDGET = 100 ether; 

    function run() external {
        vm.startBroadcast();
        
        // Deploy with value to fund the contract
        BudgetSystem budgetSystem = new BudgetSystem{value: TOTAL_BUDGET}(TOTAL_BUDGET);
        
        console.log("BudgetSystem deployed at:", address(budgetSystem));
        console.log("Total budget after deployment:", budgetSystem.getTotalBudget());
        console.log("Contract balance:", address(budgetSystem).balance);
        
        vm.stopBroadcast();
    }
}