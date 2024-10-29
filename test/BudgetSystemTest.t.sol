// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BudgetSystem} from "../src/BudgetSystem.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BudgetSystemTest is Test{
    // EVENTS
    event BudgetAllocated(address indexed department, uint256 amount);
    event FundsRequested(address indexed department, uint256 amount);
    event FundsReleased(address indexed department, uint256 amount);

    BudgetSystem private budgetSystem;

    uint256 private constant TOTAL_BUDGET = 100 ether;

    address public user = makeAddr("user");
    address payable public marketingDepartment = payable(address(1));
    address payable public itDepartment = payable(address(3));
    address payable public hrDepartment = payable(address(2));

    function setUp() external {
        budgetSystem = new BudgetSystem{value: TOTAL_BUDGET}(TOTAL_BUDGET);
    }

    ///////////////////////
    // budgetAllocation //
    //////////////////////
    function testCannotAllocateZeroAmount() external {
        uint256 amountToAllocate = 0;

        vm.expectRevert(BudgetSystem.BudgetSystem__AmountMustBeMoreThanZero.selector);
        budgetSystem.allocateBudget(itDepartment, amountToAllocate);
    }

    function testOnlyAdminCanAllocateBudget() external {
        vm.startPrank(user);
        uint256 budgetToAllocate = 10 ether;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        budgetSystem.allocateBudget(marketingDepartment, budgetToAllocate);
    }

    function testRevertIfAmountExceedsAllocatedBudget() external {
        uint256 budgetToAllocate = 1000 ether;

        vm.expectRevert(BudgetSystem.BudgetSystem__ExceededAmount.selector);
        budgetSystem.allocateBudget(hrDepartment, budgetToAllocate);
    }

    function testAllocatedBudgetWorks() external {
        uint256 budgetToAllocate = 10 ether;

        budgetSystem.allocateBudget(itDepartment, budgetToAllocate);

        uint256 expectedAllocatedBudget = budgetSystem.getAllocatedBudget(itDepartment);
        assertEq(budgetToAllocate, expectedAllocatedBudget);
    }

    function testTotalBudgetGetsDeducted() external {
    
    uint256 initialBudget = budgetSystem.getTotalBudget();
    console.log("Initial Total Budget:", initialBudget); 
    assertEq(initialBudget, 100 ether); 

    uint256 allocationAmount = 10 ether;

    budgetSystem.allocateBudget(hrDepartment, allocationAmount);

    // After allocation, total budget should decrease by 10 ether
    uint256 expectedBudget = initialBudget - allocationAmount;
    uint256 newBudget = budgetSystem.getTotalBudget();
    console.log("New Total Budget:", newBudget); 

    assertEq(newBudget, expectedBudget); 
    }


    function testAllocatedBudgetEmit() public {
        uint256 budgetToAllocate = 10 ether;
        
        vm.expectEmit(true, true, false, true);
        emit BudgetSystem.BudgetAllocated(itDepartment, budgetToAllocate);
        budgetSystem.allocateBudget(itDepartment, budgetToAllocate);
        
    }

    ///////////////////////
    // requestingFunds  //
    //////////////////////
    modifier hrBudgetAllocated {
        uint256 budgetToAllocate = 10 ether;
        budgetSystem.allocateBudget(hrDepartment, budgetToAllocate);
        _;
    }

    function testRevertsIfDepartmentHasNoBudgetAllocated() external {
        uint256 amount = 10 ether;

        vm.expectRevert(BudgetSystem.BudgetSystem__DepartmentDoesNotExist.selector);
        budgetSystem.requestFunds(amount);
    }

    function testRevertsIfAmountExceedsAllocatedBudget() external {
        uint256 amount = 500 ether; // totalBudget = 100 ether;
        uint256 budgetToAllocate = 10 ether;

        budgetSystem.allocateBudget(itDepartment, budgetToAllocate);
        vm.startPrank(itDepartment);
        vm.expectRevert(BudgetSystem.BudgetSystem__ExceedsAllocatedBudget.selector);
        budgetSystem.requestFunds(amount);
    }

    function testRequestFundsIsTrackedCorrectly() external hrBudgetAllocated{
        uint256 requestAmount = 5 ether;

        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        uint256 expectedRequestedFunds = budgetSystem.getRequestFunds(hrDepartment);
        assertEq(requestAmount, expectedRequestedFunds);
    }

    function testRequestFundsEmit() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;

        vm.startPrank(hrDepartment);
        vm.expectEmit();
        emit BudgetSystem.FundsRequested(hrDepartment, requestAmount);
        budgetSystem.requestFunds(requestAmount);
    }

    /////////////////////
    // releasedFunds  //
    ///////////////////
    function testRevertOnExceededRequestedFunds() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;
        uint256 exceededAmount = 20 ether;

        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();

        vm.expectRevert(BudgetSystem.BudgetSystem__ExceedsRequestedFunds.selector);
        budgetSystem.releaseFunds(hrDepartment, exceededAmount);
    }

    function testSpentFundsIsTrackedCorrectly() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;

        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();

        budgetSystem.releaseFunds(hrDepartment, requestAmount);

        uint256 expectedFundsSpent = budgetSystem.getSpentFunds(hrDepartment);
        assertEq(expectedFundsSpent, requestAmount);

        uint256 remainingRequestedFunds = budgetSystem.getRequestFunds(hrDepartment);
        assertEq(remainingRequestedFunds, 0); 
    }

    function testRequestedFundsIsDeductedAfterRelease() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;

        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();
        
        budgetSystem.releaseFunds(hrDepartment, requestAmount);
        uint256 expectedRequestedFundsAmount = budgetSystem.getRequestFunds(hrDepartment);
        assertEq(expectedRequestedFundsAmount, 0);
    }

    function testFundsIsAllocatedToDepartmentAfterRelease() external hrBudgetAllocated {
        // Should we make the system deduct allocated budget after a release of funds?
        uint256 requestAmount = 5 ether;
        console.log("HR Remaining budget before release funds:", budgetSystem.getRemainingBudget(hrDepartment));

        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();
        
        uint256 hrBalanceBefore = hrDepartment.balance;
        console.log("HR balance before:", hrBalanceBefore);

        // Release the funds from the budget system to the HR department
        budgetSystem.releaseFunds(hrDepartment, requestAmount);

        uint256 hrBalanceAfter = hrDepartment.balance;
        console.log("HR balance after release:", hrBalanceAfter);

        uint256 expectedHrBalance = hrBalanceBefore + requestAmount;
        assertEq(hrBalanceAfter, expectedHrBalance);
    }

    function testDepartmentReceivesFundsAfterRelease() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;
        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();

        console.log("Hr balance before:", hrDepartment.balance);
        
        budgetSystem.releaseFunds(hrDepartment, requestAmount);
        uint256 expectedHrBalance = hrDepartment.balance;
        console.log("Hr balance after release funds(transfer):", hrDepartment.balance);
        assertEq(requestAmount, expectedHrBalance);
    }

    function testReleaseFundsEmit() external hrBudgetAllocated {
        uint256 requestAmount = 5 ether;
        vm.startPrank(hrDepartment);
        budgetSystem.requestFunds(requestAmount);
        vm.stopPrank();
        
        vm.expectEmit();
        emit FundsReleased(hrDepartment, requestAmount);
        budgetSystem.releaseFunds(hrDepartment, requestAmount);
    }

}