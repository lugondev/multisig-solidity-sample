// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IBridgeConverter {
    function convert(uint256 _amount) external;

    function release(address _address, uint256 _amount) external;
}
