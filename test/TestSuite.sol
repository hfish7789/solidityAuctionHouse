// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TestFramework.sol";
import "./ArbitrationTest.sol";

contract TestLogger {

    event FailedTest(string message);
    event PassedTest(string message);
    event TotalTests(uint number);
    event PassedTests(uint number);
    event FailedTests(uint number);

    uint numPasses;
    uint numTests;
    address target;

    function TestCounter(address _target) public {
        target = _target;
    }

    function logTest(string memory name) public {
        bytes memory namebytes = abi.encode(name);
        (bool success, ) = target.call{gas:3000000}(namebytes);
        if (success) {
            emit PassedTest(name);
            numPasses += 1;
        }
        else
            emit FailedTest(name);
        numTests += 1;
    }

    function logSummary() public {
        emit TotalTests(numTests);
        emit PassedTests(numPasses);
        emit FailedTests(numTests - numPasses);
    }

}

contract TestSuite {

    //can receive money
    receive() external payable {}

    function ArbitrationTests() public {
        ArbitrationTest t = new ArbitrationTest();
        payable(t).transfer(1 ether);
        string[10] memory tests = [
            "testCreateContracts()",
            "testEarlyFinalize()",
            "testEarlyRefund()",
            "testUnauthorizedRefund()",
            "testUnauthorizedFinalize()",
            "testJudgeFinalize()",
            "testWinnerFinalize()",
            "testPublicFinalize()",
            "testJudgeRefund()",
            "testSellerRefund()"
        ];
        TestLogger logger = new TestLogger();
        for (uint i = 0; i < tests.length; i++)
            logger.logTest(tests[i]);
        logger.logSummary();
    }

    function EnglishAuctionTests() public {
        ArbitrationTest t = new ArbitrationTest();
        payable(t).transfer(1 ether);
        string[10] memory tests = [
            "testCreateContracts()",
            "testEarlyFinalize()",
            "testEarlyRefund()",
            "testUnauthorizedRefund()",
            "testUnauthorizedFinalize()",
            "testJudgeFinalize()",
            "testWinnerFinalize()",
            "testPublicFinalize()",
            "testJudgeRefund()",
            "testSellerRefund()"
        ];
        TestLogger logger = new TestLogger();
        for (uint i = 0; i < tests.length; i++)
            logger.logTest(tests[i]);
        logger.logSummary();
    }

    function allTests() public pure {}

}