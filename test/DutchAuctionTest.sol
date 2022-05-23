// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TestFramework.sol";
import "./Bidders.sol";

contract DutchAuctionTest {

    DutchAuction testAuction;
    Timer t;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;

    //can receive money
    receive() external payable {}
    constructor() {}

    function setupContracts() public {
        t = new Timer(0);
        testAuction = new DutchAuction(address(this), address(0), address(t), 300, 10, 20);
    }

    function makeBid(
        uint bidValue,
        uint bidTime,
        uint expectedPrice,
        bool expectedResult,
        string memory message
    ) internal {

        DutchAuctionBidder bidder = new DutchAuctionBidder(testAuction);
        payable(bidder).transfer(bidValue);
        uint oldTime = t.getTime();
        t.setTime(bidTime);
        uint initialAuctionBalance = address(testAuction).balance;
        address currentWinner = testAuction.getWinner();
        bool result = bidder.bid(bidValue);
        if (expectedResult == false) {
            Assert.isFalse(result, message);
            Assert.equal(address(currentWinner), testAuction.getWinner(), "no winner should be declared after invalid bid");
        }
        else{
            Assert.isTrue(result, message);
            bidder.callWithdraw();
            Assert.equal(address(testAuction).balance, initialAuctionBalance + expectedPrice, "auction should retain final price");
            Assert.equal(address(bidder).balance, bidValue - expectedPrice, "bidder should be refunded excess bid amount");
            Assert.equal(testAuction.getWinner(), address(bidder), "bidder should be declared the winner");
        }
        t.setTime(oldTime);
    }

    function testCreateDutchAuction() public {
        setupContracts();
        //do nothing, just verify that the constructor actually ran
    }

    function testLowBids() public {
        setupContracts();
        makeBid(299, 0, 0, false, "low bid should be rejected");
        makeBid(240, 2, 0, false, "low bid should be rejected");
        makeBid(100, 5, 0, false, "low bid should be rejected");
    }

    function testExactBid() public {
        setupContracts();
        makeBid(300, 0, 300, true, "exact bid should be accepted");
        setupContracts();
        makeBid(280, 1, 280, true, "exact bid should be accepted");
        setupContracts();
        makeBid(120, 9, 120, true, "exact bid should be accepted");
    }

    function testValidBidAfterInvalid() public {
        setupContracts();
        makeBid(299, 0, 0, false, "low bid should be rejected");
        makeBid(300, 0, 300, true, "valid bid after failed bid should succeed");
    }

    function testLateBid() public {
        setupContracts();
        makeBid(300, 10, 0, false, "late bid should be rejected");
    }

    function testSecondValidBid() public {
        setupContracts();
        makeBid(280, 1, 280, true, "exact bid should be accepted");
        makeBid(300, 0, 0, false, "second bid should be rejected");
    }

    function testRefundHighBid() public {
        setupContracts();
        makeBid(300, 2, 260, true, "high bid should be accepted");
    }

}