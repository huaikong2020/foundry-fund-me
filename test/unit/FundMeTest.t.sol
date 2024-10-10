// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        vm.deal(USER, STARTING_BALANCE);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        console.log("setUp");
        console.log(msg.sender);
        console.log(address(this));
        console.log(address(fundMe));
        console.log(address(fundMe.getOwner()));
    }

    function testOwner() public {
        console.log("testOwner");
        console.log(msg.sender);
        console.log(address(this));
        console.log(address(fundMe));
        console.log(address(fundMe.getOwner()));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testGetConversionRate() public {
        console.log("testGetConversionRate");
        console.log(fundMe.getConversionRate());
    }

    function testFundFailsWithoutEnoughEther() public {
        vm.expectRevert("didn't send enough ETH"); //next line will revert
        fundMe.fund{value: 1}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert(); //next line will revert
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        console.log("Gas used: ", (gasStart - gasEnd) * tx.gasprice);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        console.log(startingOwnerBalance);
        console.log(startingFundMeBalance);
        console.log(endingOwnerBalance);
        console.log(endingFundMeBalance);

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // vm.prank(fundMe.getOwner());
        // fundMe.withdraw();
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
