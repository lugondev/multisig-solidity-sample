// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IMERC20.sol";

interface IBamMERC20 is IMERC20 {
    function bridgeTokens(address _token) external view returns (bool);

    function bridgeIn(address _bridge, uint256 _amount) external;

    function bridgeOut(address _bridge, uint256 _amount) external;

    function addBridge(address _bridge) external returns (bool);

    function removeBridge(address _bridge) external returns (bool);
}
