// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBurnERC20 is IERC20Metadata {
    function burn(uint256 _amount) external;
}
