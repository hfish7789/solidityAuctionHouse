// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TestFramework.sol";
import "./Bidders.sol";

contract VickreyAuctionTestAdvanced {

    VickreyAuction testAuction;
    VickreyAuctionBidder alice;
    VickreyAuctionBidder bob;
    VickreyAuctionBidder carol;
    uint bidderCounter;

    Timer t;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;

    //can receive money
    receive() external payable {}
    constructor() {}

    function setupContracts() public {
        t = new Timer(0);
        testAuction = new VickreyAuction(address(this), address(0), address(t), 300, 10, 10, 1000);
        bidderCounter += 1;
        alice = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
        bob = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
        carol = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
    }

    function commitBid(
        VickreyAuctionBidder bidder,
        uint bidValue,
        uint bidTime,
        bool expectedResult,
        string memory message
    ) internal {

        uint oldTime = t.getTime();
        t.setTime(bidTime);
        uint initialAuctionBalance = address(testAuction).balance;

        bool result = bidder.commitBid(bidValue);

        if (expectedResult == false) {
            Assert.isFalse(result, message);
        }
        else {
            Assert.isTrue(result, message);
            Assert.equal(address(testAuction).balance, initialAuctionBalance + testAuction.bidDepositAmount(), "auction should retain deposit");
        }
        t.setTime(oldTime);
    }

    function revealBid(
        VickreyAuctionBidder bidder,
        uint bidValue,
        uint bidTime,
        bool expectedResult,
        string memory message
    ) internal {

        uint oldTime = t.getTime();
        t.setTime(bidTime);

        bool result = bidder.revealBid(bidValue);

        if (expectedResult == false) {
            Assert.isFalse(result, message);
        }
        else {
            Assert.isTrue(result, message);
        }
        t.setTime(oldTime);
    }

    function testMinimalBidder() public {
        setupContracts();

        payable(alice).transfer(5000);

        commitBid(alice, 300, 9, true, "valid bid commitment should be accepted");
        revealBid(alice, 300, 19, true, "valid bid reveal should be accepted");
        t.setTime(20);
        Assert.equal(address(alice), testAuction.getWinner(), "winner should be declared after auction end");
        testAuction.finalize();
        Assert.equal(address(alice).balance, 3700, "winner should not receive early refund");
        alice.callWithdraw();
        Assert.equal(address(alice).balance, 4700, "winner should receive partial refund");
    }

    function testRevealChangedBid() public {
        setupContracts();

        payable(alice).transfer(5000);
        payable(bob).transfer(5000);
        payable(carol).transfer(5000);

        Assert.isTrue(alice.commitBid(500, 1000), "valid bid should be accepted");
        t.setTime(1);
        
        Assert.isTrue(alice.commitBid(550, 0), "valid bid change should be accepted");

        revealBid(alice, 500, 14, false, "incorrect bid reveal should be rejected");
        revealBid(alice, 550, 14, true, "correct bid reveal should be accepted");
       
        t.setTime(20);
        Assert.equal(address(alice), testAuction.getWinner(), "winner should be declared after auction end");
                                
        testAuction.finalize();

        Assert.equal(address(alice).balance, 3450, "winner should not receive early refund");
        alice.callWithdraw();
        Assert.equal(address(alice).balance, 4700, "winner should receive partial refund");
    }

    function testMultipleBiddersOne() public {
        setupContracts();

        payable(alice).transfer(5000);
        payable(bob).transfer(5000);
        payable(carol).transfer(5000);

        commitBid(alice, 500, 1, true, "correct bid should be accepted");
        commitBid(bob, 617, 2, true, "correct bid should be accepted");
        commitBid(carol, 650, 3, true, "correct bid should be accepted");

        revealBid(alice, 500, 14, true, "correct bid reveal should be accepted");
        revealBid(bob, 617, 15, true, "correct bid reveal should be accepted");
        revealBid(carol, 650, 16, true, "correct bid reveal should be accepted");

        t.setTime(20);
        Assert.equal(address(carol), testAuction.getWinner(), "winner should be declared after auction end");
        testAuction.finalize();

        alice.callWithdraw();
        bob.callWithdraw();
        carol.callWithdraw();

        Assert.equal(address(alice).balance, 5000, "loser should receive full refund");
        Assert.equal(address(bob).balance, 5000, "loser should receive full refund");
        Assert.equal(address(carol).balance, 4383, "winner should receive partial refund");
    }

    function testMultipleBiddersTwo() public {
        setupContracts();

        payable(alice).transfer(5000);
        payable(bob).transfer(5000);
        payable(carol).transfer(5000);

        commitBid(alice, 500, 1, true, "correct bid should be accepted");
        commitBid(bob, 617, 2, true, "correct bid should be accepted");
        commitBid(carol, 650, 3, true, "correct bid reveal should be accepted");

        revealBid(carol, 650, 14, true, "correct bid reveal should be accepted");
        revealBid(alice, 500, 15, true, "correct bid reveal should be accepted");
        revealBid(bob, 617, 16, true, "correct bid reveal should be accepted");

        t.setTime(20);

        Assert.equal(address(carol), testAuction.getWinner(), "winner should be declared after auction end");
        testAuction.finalize();

        alice.callWithdraw();
        bob.callWithdraw();
        carol.callWithdraw();

        Assert.equal(address(alice).balance, 5000, "loser should receive full refund");
        Assert.equal(address(bob).balance, 5000, "loser should receive full refund");
        Assert.equal(address(carol).balance, 4383, "winner should receive partial refund");
    }
}