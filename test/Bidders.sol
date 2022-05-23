// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TestFramework.sol";

contract Bidders {}

contract Participant {

    Auction auction;

    constructor(Auction _auction) {
        setAuction(_auction);
    }

    function setAuction(Auction _auction) public {
        auction = _auction;
    }

    //wrapped call
    function callFinalize() public returns (bool success) {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("finalize()"));
    }

    //wrapped call
    function callRefund() public returns (bool success)  {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("refund()"));
    }

    //wrapped call
    function callWithdraw() public returns (bool success)  {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("withdraw()"));
    }

    //can receive money
    receive() external payable {}
}


contract DutchAuctionBidder {

    DutchAuction auction;

    constructor(DutchAuction _auction) {
        auction = _auction;
    }

    //wrapped call
    function bid(uint bidValue) public returns (bool success){
        (success, ) = address(auction).call{value:bidValue,gas:200000}(abi.encodeWithSignature("bid()"));
    }

    //wrapped call
    function callWithdraw() public returns (bool success)  {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("withdraw()"));
    }

    //can receive money
    receive() external payable {}
}

contract EnglishAuctionBidder {

    EnglishAuction auction;

    constructor(EnglishAuction _auction) {
        auction = _auction;
    }

    //wrapped call
    function bid(uint bidValue) public returns (bool success){
        (success, ) = address(auction).call{value:bidValue,gas:200000}(abi.encodeWithSignature("bid()"));
    }

    //wrapped call
    function callWithdraw() public returns (bool success)  {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("withdraw()"));
    }

    //can receive money
    receive() external payable {}
}

contract VickreyAuctionBidder {

    VickreyAuction auction;
    bytes32 nonce;

    constructor(VickreyAuction _auction, bytes32 _nonce) {
        auction = _auction;
        nonce = _nonce;
    }

    function setNonce(bytes32 _newNonce) public {
        nonce = _newNonce;
    }

    //wrapped call
    function commitBid(uint _bidValue) public returns (bool success) {
        success = commitBid(_bidValue, auction.bidDepositAmount());
    }

    //wrapped call
    function commitBid(uint _bidValue, uint _depositValue) public returns (bool success) {
        bytes32 commitment = keccak256(abi.encodePacked(_bidValue, nonce));
        (success, ) = address(auction).call{value:_depositValue,gas:200000}(abi.encodeWithSignature("commitBid(bytes32)", commitment));
    }

    //wrapped call
    function revealBid(uint _bidValue) public returns (bool success) {
        (success, ) = address(auction).call{value:_bidValue,gas:200000}(abi.encodeWithSignature("revealBid(bytes32)", nonce));
    }

    //wrapped call
    function callWithdraw() public returns (bool success)  {
        (success, ) = address(auction).call{gas:200000}(abi.encodeWithSignature("withdraw()"));
    }

    //can receive money
    receive() external payable {}
}
