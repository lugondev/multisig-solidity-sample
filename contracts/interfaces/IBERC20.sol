// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBERC20 is IERC20Metadata {
    function bridge(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}
