// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintableToken {
    function mint(address _user, uint256 _amount) external;
}
