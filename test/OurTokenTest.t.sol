// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        // Give alice some tokens to start with for transfer tests
        vm.prank(msg.sender);
        ourToken.transfer(alice, STARTING_BALANCE);
    }

    // Test Initial Supply
    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    // Test Transfer from Alice to Bob
    function testTransfer() public {
        // Check initial balances
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(bob), 0);

        // Prank as Alice to transfer to Bob
        vm.prank(alice);
        ourToken.transfer(bob, 50 ether);

        // Check balances after transfer
        assertEq(ourToken.balanceOf(alice), 50 ether);
        assertEq(ourToken.balanceOf(bob), 50 ether);
    }

    // Test Transfer Fails if Balance is Insufficient
    function testFailTransferWhenBalanceLow() public {
        vm.prank(alice);
        ourToken.transfer(bob, STARTING_BALANCE + 1);
    }

    // Test Allowance Mechanism
    function testAllowance() public {
        // Alice approves Bob to spend 20 ether
        vm.prank(alice);
        ourToken.approve(bob, 20 ether);

        assertEq(ourToken.allowance(alice, bob), 20 ether);
    }

    // Test TransferFrom (Bob spends Alice's tokens via allowance)
    function testTransferFrom() public {
        // Alice approves Bob to spend 20 ether
        vm.prank(alice);
        ourToken.approve(bob, 20 ether);

        // Bob transfers 15 ether from Alice to Bob's own address
        vm.prank(bob);
        ourToken.transferFrom(alice, bob, 15 ether);

        // Check balances after transfer
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE - 15 ether);
        assertEq(ourToken.balanceOf(bob), 15 ether);

        // Check the remaining allowance
        assertEq(ourToken.allowance(alice, bob), 5 ether);
    }

    // Test TransferFrom Fails when Allowance is Insufficient
    function testFailTransferFromWhenAllowanceLow() public {
        // Alice approves Bob to spend 10 ether
        vm.prank(alice);
        ourToken.approve(bob, 10 ether);

        // Bob tries to transfer more than the allowed amount (15 ether)
        vm.prank(bob);
        ourToken.transferFrom(alice, bob, 15 ether);  // This should fail
    }

    // Test Zero Address Transfer Reverts
    function testFailTransferToZeroAddress() public {
        vm.prank(alice);
        ourToken.transfer(address(0), 1 ether);  // This should fail
    }

    // Test Zero Address Approve Reverts
    function testFailApproveZeroAddress() public {
        vm.prank(alice);
        ourToken.approve(address(0), 1 ether);  // This should fail
    }
}
