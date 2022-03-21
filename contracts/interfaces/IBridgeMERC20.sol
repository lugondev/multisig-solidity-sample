// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IMERC20.sol";

interface IBridgeMERC20 is IMERC20 {
    function bridgeIn(address _address, uint256 _amount) external;

    function bridgeOut(address _address, uint256 _amount) external;

    function isMainMERC20(address _address) external view returns (bool);
}
