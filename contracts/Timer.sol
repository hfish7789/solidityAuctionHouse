// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Simple contract to store time. You should not need to be modify this contract.
contract Timer {

    uint256 time;
    uint256 startTime;
    address owner;

    // constructor
    constructor(uint256 _startTime) {
        owner = msg.sender;
        time = _startTime;
        startTime = _startTime;
    }

    function getTime() public view returns (uint256) {
        return time;
    }

    function resetTime() public ownerOnly {
        time = startTime;
    }

    function setTime(uint256 _newTime) public ownerOnly {
        time = _newTime;
    }

    function offsetTime(uint256 _offset) public ownerOnly {
        time += _offset;
    }

    modifier ownerOnly {
        require(msg.sender == owner, "Can only be called by owner.");
        _;
    }
}