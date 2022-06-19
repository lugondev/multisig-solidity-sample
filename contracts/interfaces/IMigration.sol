// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IMigration {
    function migrate(address _user, uint256 _amount) external;
}
