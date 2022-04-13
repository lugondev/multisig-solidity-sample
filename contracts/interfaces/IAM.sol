// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAM {
    function blacklists(address token, address user)
        external
        view
        returns (bool);

    function whitelists(address token, address user)
        external
        view
        returns (bool);
}