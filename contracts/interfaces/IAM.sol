// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAM {
    function isBlacklist(address token, address user)
        external
        view
        returns (bool);

    function isWhitelist(address token, address user)
        external
        view
        returns (bool);
}
