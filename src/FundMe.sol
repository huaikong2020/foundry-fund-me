// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;
    // uint256 public constant MINIMUM_USD = 0;

    address[] public funders;

    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_owner;

    error FundMe__NotOwner(); //agree with the two underlines
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getConversionRate() public view returns (uint256) {
        return PriceConverter.getConversionRate(1, s_priceFeed);
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 len = funders.length;
        for (uint256 i = 0; i < len; i++) {
            s_addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner,"must be ower");
        for (uint256 i = 0; i < funders.length; i++) {
            s_addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
        //transfer
        // payable(msg.sender).transfer(address(this).balance);
        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Send failed");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "not the owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
