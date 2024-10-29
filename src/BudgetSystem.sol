// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BudgetSystem
 * @author Joseph Gimba
 * @notice This contract implements a decentralized budget management system where the smart contract allocates funds to departments, 
 * and departments can request and receive funds. The system is designed to ensure efficient management of budget allocations 
 * and fund requests.
 * 
 * @dev The contract uses OpenZeppelin's Ownable for ownership control and ReentrancyGuard to prevent re-entrancy attacks. 
 * Departments can only request funds within their allocated budget, and only the owner can allocate budgets or release funds.
 * The contract also ensures no zero-value operations are allowed for budget or fund management.
 *
 * Key Features:
 * - Allocates budget to departments.
 * - Allows departments to request funds.
 * - Releases requested funds to departments.
 * - Tracks budget allocations, requests, and fund releases.
 */

contract BudgetSystem is Ownable, ReentrancyGuard {
    // ERRORS
    error BudgetSystem__ExceededAmount();
    error BudgetSystem__DepartmentDoesNotExist();
    error BudgetSystem__ExceedsAllocatedBudget();
    error BudgetSystem__ExceedsRequestedFunds();
    error BudgetSystem__AmountMustBeMoreThanZero();
    

    // STATE VARIABLES
    uint256 public totalBudget;

    struct Department {
        uint256 allocatedBudget;
        uint256 requestedFunds;
        uint256 spentFunds;
        bool exists;
    }

    mapping(address => Department) public departments;

    // EVENTS
    event BudgetAllocated(address indexed department, uint256 amount);
    event FundsRequested(address indexed department, uint256 amount);
    event FundsReleased(address indexed department, uint256 amount);

    // Modifiers
    modifier nonZero(uint256 amount) {
        if(amount <= 0){
            revert  BudgetSystem__AmountMustBeMoreThanZero();
        }
        _;
    }

    constructor(uint256 _totalBudget) Ownable(msg.sender) payable {
        totalBudget = _totalBudget;
    }

    function allocateBudget(address departmentAddress, uint256 amount) public onlyOwner nonZero(amount) {
        if (amount > totalBudget) {
            revert BudgetSystem__ExceededAmount();
        }

        departments[departmentAddress].allocatedBudget += amount;
        departments[departmentAddress].exists = true;
        totalBudget -= amount;

        emit BudgetAllocated(departmentAddress, amount);
    }

    function requestFunds(uint256 amount) public nonZero(amount) {
        Department storage dept = departments[msg.sender];
        
        if(!dept.exists){
            revert BudgetSystem__DepartmentDoesNotExist();
        }

        if(amount > dept.allocatedBudget - dept.spentFunds){
            revert BudgetSystem__ExceedsAllocatedBudget();
        }

        dept.requestedFunds += amount;
        emit FundsRequested(msg.sender, amount);
    }

    function releaseFunds(address payable departmentAddress, uint256 amount) public onlyOwner nonZero(amount) nonReentrant {
        Department storage dept = departments[departmentAddress];

        if(dept.requestedFunds < amount){
            revert BudgetSystem__ExceedsRequestedFunds();
        }
        
        dept.spentFunds += amount;
        dept.requestedFunds -= amount;
        departmentAddress.transfer(amount);  

        emit FundsReleased(departmentAddress, amount);
    }

    ///////////////////////
    // GETTER FUNCTIONS /// 
    ///////////////////////

    function getRemainingBudget(address departmentAddress) external view returns (uint256) {
        Department storage dept = departments[departmentAddress];
        return dept.allocatedBudget - dept.spentFunds;
    }

    function getAllocatedBudget(address departmentAddress) external view returns (uint256) {
        Department storage dept = departments[departmentAddress];
        return dept.allocatedBudget;
    }

    function getRequestFunds(address departmentAddress) external view returns (uint256) {
        Department storage dept = departments[departmentAddress];
        return dept.requestedFunds;
    }

    function getSpentFunds(address departmentAddress) external view returns (uint256) {
        Department storage dept = departments[departmentAddress];
        return dept.spentFunds;
    }

    function getBudgetContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalBudget() external view returns (uint256) {
        return totalBudget;
    }
    
}
