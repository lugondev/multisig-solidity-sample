// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TestProxy is Initializable {
    uint256 public storedData;
    event stored(address _to, uint256 _amount);

    function init(uint256 initVal) public initializer {
        emit stored(msg.sender, initVal);
        storedData = initVal;
    }

    function set(uint256 x) public {
        emit stored(msg.sender, x);
        storedData = x;
    }

    function get() public view returns (uint256 retVal) {
        return storedData;
    }
}
