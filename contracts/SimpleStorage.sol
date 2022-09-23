// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract SimpleStorage {
    uint256 public storedData;
    event stored(address _to, uint256 _amount);

    constructor(uint256 initVal) {
        emit stored(msg.sender, initVal);
        storedData = initVal;
    }

    function set(uint256 x) public {
        emit stored(msg.sender, x);
        storedData = x;
    }

    function callOther(address _other, bytes memory data) public {
        (bool success, ) = _other.call(data);
        require(success, "other call: failed!!!");
    }

    function setOther(address _other, uint256 x) public {
        SimpleStorage(_other).set(x);
    }

    function get() public view returns (uint256 retVal) {
        return storedData;
    }

    function getOther(address _other) public view returns (uint256 retVal) {
        return SimpleStorage(_other).get();
    }
}
