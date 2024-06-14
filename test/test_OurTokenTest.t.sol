// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {Token} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    Token public token;
    DeployOurToken public deployer;
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        token = deployer.run();
        address owner = address(this);
        token.transfer(owner, STARTING_BALANCE);
        vm.prank(owner);
    }

    function testBalance() public view {
        assertEq(token.balanceOf(bob), STARTING_BALANCE);
        assertEq(token.balanceOf(alice), 0);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;
        vm.prank(bob);
        token.approve(alice, initialAllowance);
        uint256 transferAmount = 500;
        vm.prank(alice);
        token.transferFrom(bob, alice, transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
        assertEq(token.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferFrom() public {
        uint256 amount = 5 ether;
        address owner = address(this); // Set owner to the test contract address

        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialUser1Allowance = token.allowance(owner, user1);
        console.log("Initial owner balance: ", initialOwnerBalance);
        console.log("Initial user1 allowance: ", initialUser1Allowance);
        require(initialOwnerBalance >= amount, "Owner balance is insufficient");
        require(initialUser1Allowance == 0, "User1 initial allowance is not zero");

        bool approvalSuccess = token.approve(user1, amount);
        require(approvalSuccess, "Approval failed");

        uint256 newAllowance = token.allowance(owner, user1);
        console.log("New allowance for user1: ", newAllowance);
        require(newAllowance == amount, "Allowance not set correctly");

        vm.prank(user1);
        bool transferSuccess = token.transferFrom(owner, user2, amount);
        require(transferSuccess, "TransferFrom failed");

        assertEq(token.balanceOf(owner), initialOwnerBalance - amount);
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }

    function testTransferInsufficientBalance() public {
        uint256 amount = STARTING_BALANCE + 1;
        address owner = address(this);

        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialUser1Allowance = token.allowance(owner, user1);
        console.log("Initial owner balance: ", initialOwnerBalance);
        console.log("Initial user1 allowance: ", initialUser1Allowance);
        require(initialOwnerBalance < amount, "Owner balance is sufficient");
        require(initialUser1Allowance == 0, "User1 initial allowance is not zero");

        bool approvalSuccess = token.approve(user1, amount);
        require(approvalSuccess, "Approval failed");

        uint256 newAllowance = token.allowance(owner, user1);
        console.log("New allowance for user1: ", newAllowance);
        require(newAllowance == amount, "Allowance not set correctly");

        vm.prank(user1);
        bool transferSuccess = token.transferFrom(owner, user2, amount);
        require(!transferSuccess, "TransferFrom succeeded unexpectedly");

        assertEq(token.balanceOf(owner), initialOwnerBalance);
        assertEq(token.balanceOf(user2), 0);
        assertEq(token.allowance(owner, user1), amount);
    }
}