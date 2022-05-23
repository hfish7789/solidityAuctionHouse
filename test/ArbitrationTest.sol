// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TestFramework.sol";
import "./Bidders.sol";

contract SimpleAuction is Auction {
    // constructor
    constructor(
        address _sellerAddress,
        address _judgeAddress,
        address _timerAddress,
        address _winner,
        uint256 _winningPrice
    ) payable Auction(_sellerAddress, _judgeAddress, _timerAddress) {
        if (_winner != address(0)) declareWinner(_winner, _winningPrice);
    }

    function declareWinner(address _winner, uint256 _winningPrice) public {
        winnerAddress = _winner;
        winningPrice = _winningPrice;
    }

    //can receive money
    receive() external payable {}
}

contract ArbitrationTest {
    SimpleAuction testAuction;

    // Adjust this to change the test code's initial balance
    uint256 public initialBalance = 1000000000 wei;
    Participant judge;
    Participant seller;
    Participant winner;
    Participant other;

    //can receive money
    receive() external payable {}

    constructor() payable {}

    function setupContracts(bool winnerDeclared, bool hasJudge) public {
        judge = new Participant(Auction(address(0)));
        winner = new Participant(Auction(address(0)));
        seller = new Participant(Auction(address(0)));
        other = new Participant(Auction(address(0)));

        if (hasJudge)
            testAuction = new SimpleAuction(
                address(seller),
                address(judge),
                address(0),
                address(0),
                100
            );
        else
            testAuction = new SimpleAuction(
                address(seller),
                address(0),
                address(0),
                address(0),
                100
            );

        payable(testAuction).transfer(100 wei);

        if (winnerDeclared) testAuction.declareWinner(address(winner), 100);

        judge.setAuction(testAuction);
        seller.setAuction(testAuction);
        winner.setAuction(testAuction);
        other.setAuction(testAuction);
    }

    function testCreateContracts() public {
        setupContracts(false, true);
        Assert.isFalse(false, "this test should not fail");
        Assert.isTrue(true, "this test should never fail");
        Assert.equal(uint256(7), uint256(7), "this test should never fail");
    }

    function testEarlyFinalize() public {
        setupContracts(false, true);
        Assert.isFalse(
            judge.callFinalize(),
            "finalize with no declared winner should be rejected"
        );
    }

    function testEarlyRefund() public {
        setupContracts(false, true);
        Assert.isFalse(
            judge.callRefund(),
            "refund with no declared winner should be rejected"
        );
    }

    function testUnauthorizedRefund() public {
        setupContracts(true, true);
        Assert.isFalse(
            winner.callRefund(),
            "unauthorized refund call should be rejected"
        );
        Assert.isFalse(
            other.callRefund(),
            "unauthorized refund call should be rejected"
        );
        setupContracts(true, false);
        Assert.isFalse(
            judge.callRefund(),
            "unauthorized refund call should be rejected"
        );
    }

    function testUnauthorizedFinalize() public {
        setupContracts(true, true);
        Assert.isFalse(
            seller.callFinalize(),
            "unauthorized finalize call should be rejected"
        );
        Assert.isFalse(
            other.callFinalize(),
            "unauthorized finalize call should be rejected"
        );
    }

    function testJudgeFinalize() public {
        setupContracts(true, true);
        Assert.isTrue(
            judge.callFinalize(),
            "judge finalize call should succeed"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should receive funds after finalize"
        );
    }

    function testWinnerFinalize() public {
        setupContracts(true, true);
        Assert.isTrue(
            winner.callFinalize(),
            "winner finalize call should succeed"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should receive funds after finalize"
        );
    }

    function testPublicFinalize() public {
        setupContracts(true, false);
        Assert.isTrue(
            other.callFinalize(),
            "public finalize call should succeed"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should receive funds after finalize"
        );
    }

    function testIncorrectWithdraws() public {
        setupContracts(true, true);

        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            0,
            "seller should not receive funds before finalize"
        );
        Assert.isTrue(
            winner.callWithdraw(),
            "winner withdraw call should succeed"
        );
        Assert.equal(
            address(winner).balance,
            0,
            "winner should not receive funds before finalize"
        );

        Assert.isTrue(
            winner.callFinalize(),
            "winner finalize call should succeed"
        );

        Assert.isTrue(
            winner.callWithdraw(),
            "winner withdraw call should succeed"
        );
        Assert.equal(
            address(winner).balance,
            0,
            "winner should not receive funds after finalize"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should receive funds after finalize"
        );
    }

    function testMultipleWithdraws() public {
        setupContracts(true, true);
        Assert.isTrue(
            winner.callFinalize(),
            "winner finalize call should succeed"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "seller withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should receive funds after finalize"
        );
        Assert.isTrue(
            seller.callWithdraw(),
            "second withdraw call should succeed"
        );
        Assert.equal(
            address(seller).balance,
            100,
            "seller should not receive extra funds after withdraw"
        );
    }

    function testJudgeRefund() public {
        setupContracts(true, true);
        Assert.isTrue(judge.callRefund(), "judge refund call should succeed");
        Assert.isTrue(
            winner.callWithdraw(),
            "winner withdraw call should succeed"
        );
        Assert.equal(
            address(winner).balance,
            100,
            "winner should receive funds after refund"
        );
    }

    function testSellerRefund() public {
        setupContracts(true, false);
        Assert.isTrue(seller.callRefund(), "seller refund call should succeed");
        Assert.isTrue(
            winner.callWithdraw(),
            "winner withdraw call should succeed"
        );
        Assert.equal(
            address(winner).balance,
            100,
            "winner should receive funds after refund"
        );
    }
}
